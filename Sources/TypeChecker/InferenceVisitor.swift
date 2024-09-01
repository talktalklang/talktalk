//
//  Inferencer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import TalkTalkCore
import TalkTalkSyntax

public struct Inferencer {
	let visitor = InferenceVisitor()
	let imports: [InferenceContext]
	public let context: InferenceContext

	public init(imports: [InferenceContext]) {
		// Prepend the standard library
		let stdlib = try! Library.standard.paths.flatMap {
			let source = try String(contentsOf: Library.standard.location.appending(path: $0), encoding: .utf8)
			return try Parser.parse(.init(path: $0, text: source))
		}

		self.imports = imports
		self.context = InferenceContext(
			parent: nil,
			imports: imports,
			environment: Environment(),
			constraints: Constraints()
		)

		_ = visitor.infer(stdlib, with: context)
	}

	public func infer(_ syntax: [any Syntax]) -> InferenceContext {
		return visitor.infer(syntax, with: context).solve()
	}

	public func inferDeferred() -> InferenceContext {
		return context.solveDeferred()
	}
}

struct InferenceVisitor: Visitor {
	typealias Context = InferenceContext
	typealias Value = Void

	public init() {}

	func infer(_ syntax: [any Syntax], with context: InferenceContext) -> InferenceContext {
		for syntax in syntax {
			do {
				_ = try syntax.accept(self, context)
			} catch {
				context.addError(.init(kind: .unknownError(error.localizedDescription), location: syntax.location))
			}
		}

		return context
	}

	func handleFuncLike(_ expr: any FuncLike, _ context: InferenceContext) throws {
		let childContext = context.childContext()

		try expr.params.accept(self, childContext)

		let returns = try childContext.trackReturns {
			try expr.body.accept(self, childContext)
		}

		let variables = expr.params.params.compactMap {
			if let type = childContext[$0]?.asType(in: context),
			   childContext.isFreeVariable(type)
			{
				return type
			}

			return nil
		}

		var returnType = returns.first ?? childContext[expr.body] ?? .type(.void)

		if let typeDecl = expr.typeDecl, expr.name?.lexeme != "init" {
			try typeDecl.accept(self, context)
			let inferredReturnType = returnType
			let explicitReturnType = memberTypeFrom(expr: typeDecl, in: context)
			returnType = .type(explicitReturnType)
			context.addConstraint(.equality(inferredReturnType, returnType, at: typeDecl.location))
		}

		let funcType = InferenceResult.scheme(
			Scheme(
				name: expr.name?.lexeme,
				variables: variables,
				type: .function(
					expr.params.params.map { childContext[$0]!.asType! },
					returnType.asType(in: childContext)
				)
			)
		)

		context.extend(expr, with: funcType)

		if let name = expr.name?.lexeme {
			context.defineVariable(named: name, as: funcType.asType(in: context), at: expr.location)
			childContext.defineVariable(named: name, as: funcType.asType(in: context), at: expr.location)
		}
	}

	func handleVarLet(_ expr: any VarLetDecl, _ context: InferenceContext) throws {
		try expr.typeExpr?.accept(self, context)
		try expr.value?.accept(self, context)

		let typeExpr: InferenceResult? = if let typeExpr = expr.typeExpr { context[typeExpr] } else { nil }
		let value: InferenceResult? = if let value = expr.value { context[value] } else { nil }

		var type: InferenceResult

		if context.namedVariables[expr.name] != nil {
			context.addError(InferenceError(kind: .invalidRedeclaration(expr.name), location: expr.location))
		}

		switch (typeExpr, value) {
		case let (typeExpr, value) where typeExpr != nil && value != nil:
			type = typeExpr!
			context.log("\(expr.description.components(separatedBy: .newlines)[0]) \(type) == \(value!)", prefix: " @ ")
			context.constraints.add(.equality(typeExpr!, value!, at: expr.location))
		case let (typeExpr, nil) where typeExpr != nil:
			type = .type(memberTypeFrom(expr: expr.typeExpr!, in: context))
			context.log("\(expr.description.components(separatedBy: .newlines)[0]), already has type specified: \(type)", prefix: " @ ")
		case let (nil, value) where value != nil:
			type = value!
			context.log("\(expr.description.components(separatedBy: .newlines)[0]) \(type) == \(value!)", prefix: " @ ")
		default:
			let typeVar: InferenceType = context.freshTypeVariable(expr.name + " [decl]", file: #file, line: #line)
			type = .type(typeVar)
			context.log("\(expr.description.components(separatedBy: .newlines)[0]) \(type) == \(typeVar)", prefix: " @ ")
		}

		context.defineVariable(named: expr.name, as: type.asType(in: context), at: expr.location)
		context.extend(expr, with: type)
	}

	// Return a type from a type expression, suitable for an instance member. This can include things
	// like generic parameter substitutions.
	func memberTypeFrom(expr: any TypeExpr, in context: InferenceContext) -> InferenceType {
		let type: InferenceType
		switch expr.identifier.lexeme {
		case "int":
			type = .base(.int)
		case "String":
			type = .base(.string)
		case "bool":
			type = .base(.bool)
		case "pointer":
			type = .base(.pointer)
		default:
			let found = context.lookupVariable(named: expr.identifier.lexeme) ?? .typeVar(context.freshTypeVariable(expr.identifier.lexeme))

			switch found {
			case let .structType(structType):
				var substitutions: [TypeVariable: InferenceType] = [:]

				for (typeParam, paramSyntax) in zip(structType.typeContext.typeParameters, expr.genericParams) {
					try! visit(paramSyntax, context)
					substitutions[typeParam] = context[paramSyntax]?.asType(in: context)
				}

				type = .structInstance(
					Instance(
						id: context.nextIdentifier(named: structType.name),
						type: structType,
						substitutions: substitutions
					)
				)
			case let .typeVar(typeVar):
				type = .typeVar(typeVar)
			default:
				fatalError("cannot use \(found) as type expression")
			}
		}

		return type
	}

	// Get a type from a type expression. Note that this might ignore things like generic parameters
	// in order to return a canonical form.
	func typeFrom(expr: any TypeExpr, in context: InferenceContext) -> InferenceType {
		let type: InferenceType
		switch expr.identifier.lexeme {
		case "int":
			type = .base(.int)
		case "String":
			type = .base(.string)
		case "bool":
			type = .base(.bool)
		case "pointer":
			type = .base(.pointer)
		default:
			guard let found = context.lookupVariable(named: expr.identifier.lexeme) else {
				return context.addError(.typeError("Type not found: \(expr.identifier.lexeme)"), to: expr)
			}

			switch found {
			case let .structType(structType):
				for paramSyntax in expr.genericParams {
					try! visit(paramSyntax, context)
				}

				type = .structType(structType)
			case let .typeVar(typeVar):
				type = .typeVar(typeVar)
			default:
				fatalError("cannot use \(found) as type expression")
			}
		}

		return type
	}

	// Visits

	func returnType(for result: InferenceResult, in context: InferenceContext) -> InferenceType {
		switch result {
		case .scheme(let scheme):
			let type = context.instantiate(scheme: scheme)
			return returnType(for: .type(type), in: context)
		case .type(let inferenceType):
			switch inferenceType {
			case .structType(let structType):
				return .structType(structType)
			case .function(_, let type):
				return type
			default:
				return .typeVar(context.freshTypeVariable(result.description + " -> returns", file: #file, line: #line))
			}
		}
	}

	func visit(_ expr: CallExprSyntax, _ context: InferenceContext) throws {
		try expr.callee.accept(self, context)
		for arg in expr.args {
			try arg.accept(self, context)
		}

		let callee = context[expr.callee]!
		let args = expr.args.map { context[$0]! }
		let returns = InferenceType.typeVar(context.freshTypeVariable(expr.description, file: #file, line: #line))

		context.constraints.add(
			.call(callee, args, returns: returns, at: expr.location)
		)

		context.extend(expr, with: .type(returns))
	}

	func visit(_ expr: DefExprSyntax, _ context: InferenceContext) throws {
		try expr.receiver.accept(self, context)
		try expr.value.accept(self, context)

		context.constraints.add(
			.equality(context[expr.receiver]!, context[expr.value]!, at: expr.location)
		)

		context.extend(expr, with: .type(.void))
	}

	func visit(_ expr: IdentifierExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: LiteralExprSyntax, _ context: InferenceContext) throws {
		switch expr.value {
		case .int:
			context.extend(expr, with: .type(.base(.int)))
		case .bool:
			context.extend(expr, with: .type(.base(.bool)))
		case .string:
			context.extend(expr, with: .type(.base(.string)))
		case .none:
			context.extend(expr, with: .type(.base(.nope)))
		}
	}

	func visit(_ expr: VarExprSyntax, _ context: InferenceContext) throws {
		if let defined = context.lookupVariable(named: expr.name) {
			context.extend(
				expr,
				with: .type(
					context.applySubstitutions(to: defined)
				)
			)
		} else if let type = context.lookupType(named: expr.name) {
			context.extend(expr, with: .type(.kind(type)))
		} else {
			let typeVar = context.freshTypeVariable(expr.name)
			context.definePlaceholder(named: expr.name, as: .placeholder(typeVar), at: expr.location)
			context.extend(expr, with: .type(.placeholder(typeVar)))
		}
	}

	func visit(_ expr: UnaryExprSyntax, _ context: InferenceContext) throws {
		try expr.expr.accept(self, context)
		context.extend(expr, with: context[expr.expr]!)
	}

	func visit(_ expr: BinaryExprSyntax, _ context: InferenceContext) throws {
		try expr.lhs.accept(self, context)
		try expr.rhs.accept(self, context)

		guard case let .type(lhs) = context[expr.lhs] else {
			context.addError(.unknownError("invalid infix operand: \(expr.lhs)"), to: expr.lhs)
			return
		}

		guard case let .type(rhs) = context[expr.rhs] else {
			context.addError(.unknownError("invalid infix operand: \(expr.rhs)"), to: expr.rhs)
			return
		}

		let returns: TypeVariable = context.freshTypeVariable(expr.description + " [binop]", file: #file, line: #line)

		context.constraints.add(
			InfixOperatorConstraint(
				op: expr.op,
				lhs: lhs,
				rhs: rhs,
				returns: returns,
				context: context,
				location: expr.location
			)
		)

		context.extend(expr, with: .type(.typeVar(returns)))
	}

	func visit(_ expr: IfExprSyntax, _ context: InferenceContext) throws {
		try expr.condition.accept(self, context)
		try expr.consequence.accept(self, context)
		try expr.alternative.accept(self, context)

		context.addConstraint(
			.equality(context[expr.consequence]!, context[expr.alternative]!, at: expr.location)
		)

		context.extend(expr, with: context[expr.consequence]!)
	}

	func visit(_ expr: WhileStmtSyntax, _ context: InferenceContext) throws {
		try expr.condition.accept(self, context)
		try expr.body.accept(self, context)
		context.extend(expr, with: .type(.void))
	}

	func visit(_ expr: BlockStmtSyntax, _ context: InferenceContext) throws {
		for stmt in expr.stmts {
			try stmt.accept(self, context)
		}

		if let lastStmt = expr.stmts.last, let result = context[lastStmt] {
			context.extend(expr, with: result)
		} else {
			context.extend(expr, with: .type(.void))
		}
	}

	func visit(_ expr: FuncExprSyntax, _ context: InferenceContext) throws {
		try handleFuncLike(expr, context)
	}

	func visit(_ expr: ParamsExprSyntax, _ context: InferenceContext) throws {
		for param in expr.params {
			try param.accept(self, context)
		}

		context.extend(expr, with: .type(.void))
	}

	func visit(_ expr: ParamSyntax, _ context: InferenceContext) throws {
		var type: InferenceType

		if let typeExpr = expr.type {
			type = typeFrom(expr: typeExpr, in: context)
		} else {
			type = .typeVar(context.freshTypeVariable(expr.name, file: #file, line: #line))
		}

		context.defineVariable(named: expr.name, as: type, at: expr.location)
		context.extend(expr, with: .type(type))
	}

	func visit(_ expr: GenericParamsSyntax, _ context: InferenceContext) throws {
		#warning("TODO")
	}

	func visit(_ expr: CallArgument, _ context: InferenceContext) throws {
		try expr.value.accept(self, context)
		context.extend(expr, with: context[expr.value]!)
	}

	func visit(_ expr: StructExprSyntax, _ context: InferenceContext) throws {
		#warning("TODO")
	}

	func visit(_ expr: DeclBlockSyntax, _ context: InferenceContext) throws {
		for decl in expr.decls {
			try decl.accept(self, context)
		}

		context.extend(expr, with: .type(.void))
	}

	func visit(_ expr: VarDeclSyntax, _ context: InferenceContext) throws {
		try handleVarLet(expr, context)
	}

	func visit(_ expr: LetDeclSyntax, _ context: InferenceContext) throws {
		try handleVarLet(expr, context)
	}

	func visit(_ expr: ParseErrorSyntax, _ context: InferenceContext) throws {
		#warning("TODO")
	}

	func visit(_ expr: MemberExprSyntax, _ context: InferenceContext) throws {
		try expr.receiver.accept(self, context)
		let returns: InferenceType?

		switch context[expr.receiver] {
//		case let .type(.structInstance(receiver)):
//			returns = receiver.member(named: expr.property)!
		case let .type(.structType(structType)):
			returns = structType.member(named: expr.property)?.asType(in: context)

			guard returns != nil else {
				context.addError(.memberNotFound(structType, expr.property), to: expr)
				return
			}
		default:
			returns = .typeVar(context.freshTypeVariable(expr.description, file: #file, line: #line))
		}

		context.constraints.add(
			MemberConstraint(
				receiver: context[expr.receiver]!,
				name: expr.property,
				type: .type(returns!),
				location: expr.location
			)
		)

		context.extend(expr, with: .type(returns!))
	}

	func visit(_ expr: ReturnStmtSyntax, _ context: InferenceContext) throws {
		try expr.value?.accept(self, context)

		if let value = expr.value {
			context.trackReturn(context[value]!)
			context.extend(expr, with: context[value]!)
		} else {
			context.extend(expr, with: .type(.void))
		}
	}

	func visit(_ expr: InitDeclSyntax, _ context: InferenceContext) throws {
		try handleFuncLike(expr, context)
	}

	func visit(_ expr: ImportStmtSyntax, _ context: InferenceContext) throws {
		context.log("TODO", prefix: " ? ")
	}

	func visit(_ expr: TypeExprSyntax, _ context: InferenceContext) throws {
		context.extend(expr, with: .type(typeFrom(expr: expr, in: context)))
	}

	func visit(_ expr: ExprStmtSyntax, _ context: InferenceContext) throws {
		try expr.expr.accept(self, context)
		context.extend(expr, with: context[expr.expr]!)
	}

	func visit(_ expr: IfStmtSyntax, _ context: InferenceContext) throws {
		try expr.condition.accept(self, context)
		try expr.consequence.accept(self, context)
		try expr.alternative?.accept(self, context)
		context.extend(expr, with: .type(.void))
	}

	func visit(_ expr: StructDeclSyntax, _ context: InferenceContext) throws {
		let structType = StructType(
			name: expr.name,
			parentContext: context
		)

		let structContext = structType.context
		let typeContext = structType.typeContext

		for typeParameter in expr.typeParameters {
			// Define the name first
			let typeVar: TypeVariable = structContext.freshTypeVariable("\(typeParameter.identifier.lexeme)", file: #file, line: #line)

			typeContext.typeParameters.append(typeVar)

			// Add this type to the struct's named variables for resolution
			structContext.defineVariable(named: typeParameter.identifier.lexeme, as: .typeVar(typeVar), at: typeParameter.location)

			try visit(typeParameter, structContext)
		}

		let structInferenceType = InferenceType.structType(structType)

		// Make this type available by name outside its own context
		context.defineVariable(named: expr.name, as: structInferenceType, at: expr.location)

		for typeParameter in expr.conformances {
			try typeParameter.accept(self, structContext)

			context.constraints.add(
				TypeConformanceConstraint(
					type: structInferenceType,
					conformsTo: context[typeParameter]!.asType(in: context),
					location: typeParameter.location
				)
			)
		}

		for decl in expr.body.decls {
			try decl.accept(self, structContext)

			switch (decl, structContext[decl]!) {
			case let (decl as FuncExpr, .scheme(scheme)):
				// It's a method
				typeContext.methods[decl.name!.lexeme] = .scheme(scheme)
			case let (decl as VarLetDecl, .type(type)):
				// It's a property
				typeContext.properties[decl.name] = .type(type)
			case let (_ as InitDecl, type):
				typeContext.initializers["init"] = type
			default:
				print("!! Unhandled struct body decl:")
				print(decl.description)
			}
		}

		context.extend(expr, with: .type(structInferenceType))
	}

	func visit(_ expr: ArrayLiteralExprSyntax, _ context: InferenceContext) throws {
		let elements = try expr.exprs.map { try $0.accept(self, context) ; return context[$0] }
		let arrayType = context.lookupVariable(named: "Array")!
		let arrayStructType = StructType.extractType(from: .type(arrayType))!

		// TODO: Handle homogenous arrays or error
		let arrayInstance = arrayStructType.instantiate(with: [:], in: context)
		let elementTypeParameter = arrayStructType.typeContext.typeParameters[0]
		assert(elementTypeParameter.name == "Element", "didn't get correct type parameter")

		if !elements.isEmpty, let elementType = elements[0]?.asType(in: context) {
			arrayInstance.substitutions[elementTypeParameter] = elementType
		}

		let returns = InferenceType.structInstance(arrayInstance)

		context.addConstraint(
			.call(
				.type(arrayType),
				[],
				returns: returns,
				at: expr.location
			)
		)

		context.extend(expr, with: .type(returns))
	}

	func visit(_ expr: SubscriptExprSyntax, _ context: InferenceContext) throws {
		try expr.receiver.accept(self, context)
		let args = try expr.args.map { try $0.accept(self, context) ; return context[$0]! }
		var returns = returnType(for: context[expr.receiver]!, in: context)

		// TODO: Why doesn't we get a consistent result here?
		switch context[expr.receiver]?.asType(in: context) {
		case let .structType(structType), let .selfVar(structType):
			let method = structType.member(named: "get")!

			// We can assume it's a method so we can destructure to get our return type
			guard case let .function(_, getReturns) = method.asType(in: context) else {
				return
			}

			returns = getReturns

			context.addConstraint(
				.call(method, args, returns: getReturns, at: expr.location)
			)
		case let .structInstance(structInstance):
			let method = structInstance.member(named: "get")!

			context.addConstraint(
				.call(.type(method), args, returns: returns, at: expr.location)
			)
		default:
			let typeVar = context.freshTypeVariable("\(expr.description)")
			returns = .typeVar(typeVar)

			context.addConstraint(
				SubscriptConstraint(
					receiver: context[expr.receiver]!,
					args: expr.args.map { context[$0]! },
					returns: .typeVar(typeVar),
					location: expr.location,
					isRetry: false
				)
			)
		}

		context.extend(expr, with: .type(returns))
	}

	func visit(_ expr: DictionaryLiteralExprSyntax, _ context: InferenceContext) throws {
		for elem in expr.elements { try elem.accept(self, context) }
		let dictType = context.lookupVariable(named: "Dictionary")!
		let dictStructType = StructType.extractType(from: .type(dictType))!

		let dictInstance = dictStructType.instantiate(with: [:], in: context)
		let keyType = dictStructType.typeContext.typeParameters[0]
		let valueType = dictStructType.typeContext.typeParameters[1]
		assert(keyType.name == "Key", "didn't get correct Key type parameter, got \(keyType.name ?? "<none>")")
		assert(valueType.name == "Value", "didn't get correct Value type parameter, got \(valueType.name ?? "<none>")")

		if let element = expr.elements.first {
			dictInstance.substitutions[keyType] = context[element.key]!.asType(in: context)
			dictInstance.substitutions[valueType] = context[element.value]!.asType(in: context)
		}

		let returns = InferenceType.structInstance(dictInstance)

		context.addConstraint(
			.call(
				.type(dictType),
				[],
				returns: returns,
				at: expr.location
			)
		)

		context.extend(expr, with: .type(returns))
	}

	func visit(_ expr: DictionaryElementExprSyntax, _ context: InferenceContext) throws {
		try expr.key.accept(self, context)
		try expr.value.accept(self, context)

		// Dictionary elements don't have any type on their own
		context.extend(expr, with: .type(.void))
	}

	func visit(_ expr: ProtocolDeclSyntax, _ context: Context) throws {
		let protocolType = ProtocolType(name: expr.name.lexeme)
		let protocolTypeVar: InferenceType = context.freshTypeVariable(expr.name.lexeme, file: #file, line: #line)

		context.constraints.add(
			EqualityConstraint(
				lhs: .type(.protocol(protocolType)),
				rhs: .type(protocolTypeVar),
				location: expr.location
			)
		)

		context.extend(expr, with: .type(.protocol(protocolType)))
	}

	func visit(_ expr: ProtocolBodyDeclSyntax, _ context: Context) throws {
		#warning("Generated by Dev/generate-type.rb")
	}

	func visit(_ expr: FuncSignatureDeclSyntax, _ context: Context) throws {
		#warning("Generated by Dev/generate-type.rb")
	}

	// GENERATOR_INSERTION
}
