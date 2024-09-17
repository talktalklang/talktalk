//
//  InferenceVisitor.swift
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

	public init(imports: [InferenceContext]) throws {
		// Prepend the standard library
		let stdlib = try Library.standard.paths.flatMap {
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
		visitor.infer(syntax, with: context).solve()
	}

	public func inferDeferred() -> InferenceContext {
		context.solveDeferred()
	}
}

struct InferenceVisitor: Visitor {
	typealias Context = InferenceContext
	typealias Value = Void

	public init() {}

	func placeholdDecls(for syntax: [any Syntax], in context: InferenceContext) {
		// Just to through the syntax here and create placeholders for decls if we don't know about them already
		for decl in syntax where decl is Decl {
			switch decl {
			case let decl as EnumDecl:
				context.definePlaceholder(named: decl.nameToken.lexeme, as: .placeholder(context.freshTypeVariable(decl.nameToken.lexeme)), at: decl.location)
			case let decl as StructDecl:
				if !context.exists(syntax: decl) {
					context.definePlaceholder(named: decl.name, as: .placeholder(context.freshTypeVariable(decl.name)), at: decl.location)
				}
			case let decl as ProtocolDecl:
				context.definePlaceholder(named: decl.name.lexeme, as: .placeholder(context.freshTypeVariable(decl.name.lexeme)), at: decl.location)
			default:
				()
			}
		}
	}

	func infer(_ syntax: [any Syntax], with context: InferenceContext) -> InferenceContext {
		placeholdDecls(for: syntax, in: context)

		for syntax in syntax {
			do {
				_ = try syntax.accept(self, context)
			} catch {
				context.addError(.init(kind: .unknownError(error.localizedDescription), location: syntax.location))
			}
		}

		return context
	}

	func parameters(of type: InferenceType, in context: InferenceContext, with substitutions: [TypeVariable: InferenceType]? = nil) throws -> [InferenceType] {
		switch type {
		case let .function(params, _):
			params
		case let .enumCase(enumCase):
			if let substitutions, !substitutions.isEmpty {
				enumCase.instantiate(in: context, with: substitutions).attachedTypes
			} else {
				enumCase.attachedTypes
			}
		default:
			[]
		}
	}

	func handleFuncLike(_ expr: any FuncLike, _ context: InferenceContext, isInit: Bool) throws {
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

		var returnType: InferenceResult
		if isInit {
			guard let selfVar = context.lookupVariable(named: "self") else {
				throw InferencerError.cannotInfer("did not find self for \(expr.description)")
			}

			returnType = .type(selfVar)
		} else {
			returnType = returns.first ?? childContext[expr.body] ?? .type(.void)
		}

		if let typeDecl = expr.typeDecl, expr.name?.lexeme != "init" {
			try typeDecl.accept(self, context)
			let inferredReturnType = returnType
			let explicitReturnType = try memberTypeFrom(expr: typeDecl, in: context)
			returnType = .type(explicitReturnType)
			context.addConstraint(.equality(inferredReturnType, returnType, at: typeDecl.location))
		}

		let funcType = try InferenceResult.scheme(
			Scheme(
				name: expr.name?.lexeme,
				variables: variables,
				type: .function(
					expr.params.params.map {
						try childContext.get($0).asType(in: childContext)
					},
					childContext.applySubstitutions(to: returnType.asType(in: childContext))
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
			// swiftlint:disable force_unwrapping
			type = typeExpr!
			context.log("\(expr.description.components(separatedBy: .newlines)[0]) \(type) == \(value!)", prefix: " @ ")
			context.constraints.add(.equality(typeExpr!, value!, at: expr.location))
		case let (typeExpr, nil) where typeExpr != nil:
			type = try .type(memberTypeFrom(expr: expr.typeExpr!, in: context))
			context.log("\(expr.description.components(separatedBy: .newlines)[0]), already has type specified: \(type)", prefix: " @ ")
		case let (nil, value) where value != nil:
			type = value!
			context.log("\(expr.description.components(separatedBy: .newlines)[0]) \(type) == \(value!)", prefix: " @ ")
		default:
			let typeVar: InferenceType = context.freshTypeVariable(expr.name + " [decl]", file: #file, line: #line)
			type = .type(typeVar)
			context.log("\(expr.description.components(separatedBy: .newlines)[0]) \(type) == \(typeVar)", prefix: " @ ")
			// swiftlint:enable force_unwrapping
		}

		context.defineVariable(named: expr.name, as: type.asType(in: context), at: expr.location)
		context.extend(expr, with: type)
	}

	// Return a type from a type expression, suitable for an instance member. This can include things
	// like generic parameter substitutions.
	func memberTypeFrom(expr: any TypeExpr, in context: InferenceContext) throws -> InferenceType {
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
					try visit(paramSyntax, context)
					substitutions[typeParam] = context[paramSyntax]?.asType(in: context)
				}

				type = .structInstance(
					Instance(
						id: context.nextIdentifier(named: structType.name),
						type: structType,
						substitutions: substitutions
					)
				)
			case let .protocol(protocolType):
				type = .boxedInstance(Instance(id: context.nextIdentifier(named: protocolType.name), type: protocolType, substitutions: [:]))
			case let .typeVar(typeVar):
				type = .typeVar(typeVar)
			case let .enumType(enumType):
				type = .enumType(enumType)
			case let .placeholder(placeholder):
				type = .placeholder(placeholder)
			default:
				throw InferencerError.cannotInfer("cannot use \(found) as type expression")
			}
		}

		return type
	}

	// Get a type from a type expression. Note that this might ignore things like generic parameters
	// in order to return a canonical form.
	func typeFrom(expr: any TypeExpr, in context: InferenceContext) throws -> InferenceType {
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
			let found: InferenceType

			if let existing = context.lookupVariable(named: expr.identifier.lexeme) ?? context.lookupPlaceholder(named: expr.identifier.lexeme) {
				found = existing
			} else if let typeContext = context.typeContext, let typeParam = typeContext.typeParameters.first(where: { $0.name == expr.identifier.lexeme }) {
				found = .typeVar(typeParam)
				context.definePlaceholder(named: expr.identifier.lexeme, as: .placeholder(typeParam), at: expr.location)
			} else {
				return context.addError(.typeError("\(expr.identifier.lexeme) not found"), to: expr)
			}

			switch found {
			case let .structType(structType):
				for paramSyntax in expr.genericParams {
					try visit(paramSyntax, context)
				}

				type = .structType(structType)
			case let .protocol(protocolType):
				type = .protocol(protocolType)
			case let .enumType(enumType):
				type = .enumType(enumType)
			case let .typeVar(typeVar):
				type = .typeVar(typeVar)
			case let .placeholder(typeVar):
				type = .placeholder(typeVar)
			default:
				throw InferencerError.cannotInfer("cannot use \(found) as type expression")
			}
		}

		return type
	}

	func inferPattern(from syntax: any Syntax, in context: InferenceContext) throws {
		let patternVisitor = PatternVisitor(inferenceVisitor: self)
		let pattern = try syntax.accept(patternVisitor, context)

		context.extend(syntax, with: .type(.pattern(pattern)))
	}

	// Visits

	func returnType(for result: InferenceResult, in context: InferenceContext) -> InferenceType {
		switch result {
		case let .scheme(scheme):
			let type = context.instantiate(scheme: scheme)
			return returnType(for: .type(type), in: context)
		case let .type(inferenceType):
			switch inferenceType {
			case let .structType(structType):
				return .structType(structType)
			case let .function(_, type):
				return type
			default:
				return .typeVar(context.freshTypeVariable(result.description + " -> returns", file: #file, line: #line))
			}
		}
	}

	func visit(_ expr: CallExprSyntax, _ context: InferenceContext) throws {
		try expr.callee.accept(self, context)

		let callee = try context.get(expr.callee)
		let params = try parameters(of: callee.asType(in: context), in: context)

		for (i, arg) in expr.args.enumerated() {
			if params.count == expr.args.count {
				// If we can match the arg with a param, try to expect it.
				try visit(arg, context.expecting(params[i]))
			} else {
				try visit(arg, context)
			}
		}

		let args = try expr.args.map { try context.get($0) }

		let returns: InferenceType = if case let .enumCase(enumCase) = context.lookup(syntax: expr.callee) {
			// If we determine the callee to be an enum case, then its type is actually the enum type.
			InferenceType.enumType(enumCase.type)
		} else {
			InferenceType.typeVar(context.freshTypeVariable(expr.description, file: #file, line: #line))
		}

		context.constraints.add(
			.call(callee, args, returns: returns, at: expr.location)
		)

		context.extend(expr, with: .type(returns))
	}

	func visit(_ expr: DefExprSyntax, _ context: InferenceContext) throws {
		try expr.receiver.accept(self, context)
		try expr.value.accept(self, context)

		try context.constraints.add(
			.equality(context.get(expr.receiver), context.get(expr.value), at: expr.location)
		)

		context.extend(expr, with: .type(.void))
	}

	func visit(_: IdentifierExprSyntax, _: InferenceContext) throws {
		// Nothing to do here since it's handled in var expr.
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
		} else if let type = context.lookupPrimitive(named: expr.name) {
			context.extend(expr, with: .type(.kind(type)))
		} else if let expectation = context.expectation {
			context.extend(expr, with: .type(expectation))
		} else {
			let typeVar = context.freshTypeVariable(expr.name)
			context.definePlaceholder(named: expr.name, as: .placeholder(typeVar), at: expr.location)
			context.extend(expr, with: .type(.placeholder(typeVar)))
		}
	}

	func visit(_ expr: UnaryExprSyntax, _ context: InferenceContext) throws {
		try expr.expr.accept(self, context)
		try context.extend(expr, with: context.get(expr.expr))
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

		try context.addConstraint(
			.equality(context.get(expr.consequence), context.get(expr.alternative), at: expr.location)
		)

		try context.extend(expr, with: context.get(expr.consequence))
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
		try handleFuncLike(expr, context, isInit: false)
	}

	func visit(_ expr: ParamsExprSyntax, _ context: InferenceContext) throws {
		for param in expr.params {
			try param.accept(self, context)
		}

		context.extend(expr, with: .type(.void))
	}

	func visit(_ expr: ParamSyntax, _ context: InferenceContext) throws {
		let type: InferenceType = if let typeExpr = expr.type {
			try memberTypeFrom(expr: typeExpr, in: context)
		} else {
			.typeVar(context.freshTypeVariable(expr.name, file: #file, line: #line))
		}

		context.defineVariable(named: expr.name, as: type, at: expr.location)
		context.extend(expr, with: .type(type))
	}

	func visit(_: GenericParamsSyntax, _: InferenceContext) throws {
		// Handled in type expr visits
	}

	func visit(_ expr: Argument, _ context: InferenceContext) throws {
		try expr.value.accept(self, context)
		try context.extend(expr, with: context.get(expr.value))
	}

	func visit(_: StructExprSyntax, _: InferenceContext) throws {
		// We don't really handle these yet
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

	func visit(_: ParseErrorSyntax, _: InferenceContext) throws {
		// Nothing to be done here
	}

	func visit(_ expr: MemberExprSyntax, _ context: InferenceContext) throws {
		try expr.receiver?.accept(self, context)
		let returns: InferenceType

		let receiver: InferenceResult? = if let rec = expr.receiver {
			context[rec]
		} else if let expectation = context.expectation {
			.type(expectation)
		} else if let matchContext = context.matchContext {
			.type(matchContext.target)
		} else {
			nil
		}

		switch receiver {
		case let .type(.structType(structType)):
			guard let member = structType.member(named: expr.property, in: context)?.asType(in: context) else {
				context.addError(.memberNotFound(.structType(structType), expr.property), to: expr)
				return
			}

			returns = member
		case let .type(.enumCase(enumCase)):
			returns = .enumCase(enumCase)
		case let .type(.enumType(enumType)):
			guard let member = enumType.cases.first(where: { $0.name == expr.property }) else {
				context.addError(.memberNotFound(.enumType(enumType), expr.property), to: expr)
				return
			}

			returns = .enumCase(member)
		default:
			returns = .typeVar(context.freshTypeVariable(expr.description, file: #file, line: #line))
		}

		context.constraints.add(
			MemberConstraint(
				receiver: receiver ?? .type(.typeVar(context.freshTypeVariable("RECEIVER" + expr.description))),
				name: expr.property,
				type: .type(returns),
				location: expr.location
			)
		)

		context.extend(expr, with: .type(returns))
	}

	func visit(_ expr: ReturnStmtSyntax, _ context: InferenceContext) throws {
		try expr.value?.accept(self, context)

		if let value = expr.value {
			try context.trackReturn(context.get(value))
			try context.extend(expr, with: context.get(value))
		} else {
			context.extend(expr, with: .type(.void))
		}
	}

	func visit(_ expr: InitDeclSyntax, _ context: InferenceContext) throws {
		try handleFuncLike(expr, context, isInit: true)
	}

	func visit(_: ImportStmtSyntax, _ context: InferenceContext) throws {
		context.log("TODO", prefix: " ? ")
	}

	func visit(_ expr: TypeExprSyntax, _ context: InferenceContext) throws {
		try context.extend(expr, with: .type(typeFrom(expr: expr, in: context)))
	}

	func visit(_ expr: ExprStmtSyntax, _ context: InferenceContext) throws {
		try expr.expr.accept(self, context)
		let result = try context.get(expr.expr)

		context.extend(expr, with: result)
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
			structContext.defineVariable(
				named: typeParameter.identifier.lexeme,
				as: .typeVar(typeVar),
				at: typeParameter.location
			)

			try visit(typeParameter, structContext)
		}

		let structInferenceType = InferenceType.structType(structType)

		// Make this type available by name outside its own context
		context.defineVariable(named: expr.name, as: structInferenceType, at: expr.location)

		for typeParameter in expr.conformances {
			try typeParameter.accept(self, structContext)

			try context.constraints.add(
				TypeConformanceConstraint(
					type: .type(structInferenceType),
					conformsTo: context.get(typeParameter),
					location: typeParameter.location
				)
			)
		}

		// Make `self` available inside the struct
		structContext.defineVariable(
			named: "self",
			as: .selfVar(.structType(structType)),
			at: [.synthetic(.struct)]
		)

		for decl in expr.body.decls {
			try decl.accept(self, structContext)

			switch try (decl, structContext.get(decl)) {
			case let (decl as FuncExpr, .scheme(scheme)):
				guard let name = decl.name?.lexeme else {
					throw InferencerError.cannotInfer("No name found for member \(decl.description)")
				}

				// It's a method
				typeContext.methods[name] = .scheme(scheme)
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
		let elements = try expr.exprs.map { try $0.accept(self, context); return context[$0] }

		guard let arrayType = context.lookupVariable(named: "Array") else {
			throw InferencerError.cannotInfer("No Array type found from stdlib")
		}

		guard let arrayStructType = StructType.extractType(from: .type(arrayType)) else {
			throw InferencerError.cannotInfer("Could not get Array struct type")
		}

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
		let args = try expr.args.map { try $0.accept(self, context); return try context.get($0) }
		var returns = try returnType(for: context.get(expr.receiver), in: context)

		// TODO: Why doesn't we get a consistent result here?
		switch context[expr.receiver]?.asType(in: context) {
		case let .selfVar(.structType(type)):
			guard let method = type.typeContext.methods["get"] else {
				throw InferencerError.cannotInfer("No `get` method for \(type)")
			}

			// We can assume it's a method so we can destructure to get our return type
			guard case let .function(_, getReturns) = method.asType(in: context) else {
				return
			}

			returns = getReturns
		case let .structType(structType):
			guard let method = structType.member(named: "get", in: context) else {
				throw InferencerError.cannotInfer("No `get` method for \(structType)")
			}

			// We can assume it's a method so we can destructure to get our return type
			guard case let .function(_, getReturns) = method.asType(in: context) else {
				return
			}

			returns = getReturns

			context.addConstraint(
				.call(method, args, returns: getReturns, at: expr.location)
			)
		case let .structInstance(structInstance):
			guard let method = structInstance.member(named: "get", in: context) else {
				throw InferencerError.cannotInfer("No `get` meethod for \(structInstance)")
			}

			context.addConstraint(
				.call(.type(method), args, returns: returns, at: expr.location)
			)
		default:
			let typeVar = context.freshTypeVariable("\(expr.description)")
			returns = .typeVar(typeVar)

			try context.addConstraint(
				SubscriptConstraint(
					receiver: context.get(expr.receiver),
					args: expr.args.map { try context.get($0) },
					returns: .typeVar(typeVar),
					location: expr.location,
					isRetry: false
				)
			)
		}

		context.extend(expr, with: .type(returns))
	}

	func visit(_ expr: DictionaryLiteralExprSyntax, _ context: InferenceContext) throws {
		for elem in expr.elements {
			try elem.accept(self, context)
		}
		guard let dictType = context.lookupVariable(named: "Dictionary"),
		      let dictStructType = StructType.extractType(from: .type(dictType))
		else {
			throw InferencerError.cannotInfer("No Dictionary found from stdlib")
		}

		let dictInstance = dictStructType.instantiate(with: [:], in: context)
		let keyType = dictStructType.typeContext.typeParameters[0]
		let valueType = dictStructType.typeContext.typeParameters[1]
		assert(keyType.name == "Key", "didn't get correct Key type parameter, got \(keyType.name ?? "<none>")")
		assert(valueType.name == "Value", "didn't get correct Value type parameter, got \(valueType.name ?? "<none>")")

		if let element = expr.elements.first {
			dictInstance.substitutions[keyType] = try context.get(element.key).asType(in: context)
			dictInstance.substitutions[valueType] = try context.get(element.value).asType(in: context)
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
		let childContext = context.childTypeContext(named: expr.name.lexeme)

		// swiftlint:disable force_unwrapping
		let typeContext = childContext.typeContext!
		// swiftlint:enable force_unwrapping

		let protocolType = ProtocolType(name: expr.name.lexeme, typeContext: typeContext)
		context.defineVariable(named: expr.name.lexeme, as: .protocol(protocolType), at: expr.location)

		// swiftlint:disable force_unwrapping
		let protocolTypeVar = context.lookupVariable(named: expr.name.lexeme)!
		// swiftlint:enable force_unwrapping

		for typeParameter in expr.typeParameters {
			// Define the name first
			let typeVar: TypeVariable = childContext.freshTypeVariable("\(typeParameter.identifier.lexeme)", file: #file, line: #line)

			typeContext.typeParameters.append(typeVar)

			// Add this type to the struct's named variables for resolution
			childContext.defineVariable(
				named: typeParameter.identifier.lexeme,
				as: .typeVar(typeVar),
				at: typeParameter.location
			)

			try visit(typeParameter, childContext)
		}

		context.constraints.add(
			EqualityConstraint(
				lhs: .type(.protocol(protocolType)),
				rhs: .type(protocolTypeVar),
				location: expr.location
			)
		)

		try expr.body.accept(self, childContext)

		// Save property requirements for the protocol
		for decl in expr.body.decls {
			guard let decl = decl as? VarLetDecl else {
				continue
			}

			if let type = context[decl] {
				typeContext.properties[decl.name] = type
			}
		}

		context.extend(expr, with: .type(.protocol(protocolType)))
	}

	func visit(_ decl: ProtocolBodyDeclSyntax, _ context: Context) throws {
		for decl in decl.decls {
			try decl.accept(self, context)
		}
	}

	func visit(_ decl: FuncSignatureDeclSyntax, _ context: Context) throws {
		guard let typeContext = context.typeContext else {
			throw InferencerError.cannotInfer("No type context to define func signature in")
		}

		let params = try decl.params.params.map {
			try $0.accept(self, context)

			guard let type = context[$0]?.asType(in: context) else {
				throw InferencerError.cannotInfer("Could not determine parameter type: \($0.description)")
			}

			return type
		}

		try decl.returnDecl.accept(self, context)
		guard let returnType = context[decl.returnDecl]?.asType(in: context) else {
			throw InferencerError.cannotInfer("Could not determine return type: \(decl.description)")
		}

		typeContext.methods[decl.name.lexeme] = .scheme(Scheme(
			name: decl.name.lexeme,
			variables: [],
			type: .function(params, returnType)
		))
	}

	public func visit(_ expr: EnumDeclSyntax, _ context: Context) throws {
		let enumContext = context.childTypeContext(named: expr.nameToken.lexeme)

		guard let typeContext = enumContext.typeContext else {
			throw InferencerError.cannotInfer("No type context found for \(expr)")
		}

		for typeParameter in expr.typeParams {
			// Define the name first
			let typeVar: TypeVariable = enumContext.freshTypeVariable("\(typeParameter.identifier.lexeme)", file: #file, line: #line)

			typeContext.typeParameters.append(typeVar)

			// Add this type to the struct's named variables for resolution
			enumContext.defineVariable(
				named: typeParameter.identifier.lexeme,
				as: .typeVar(typeVar),
				at: typeParameter.location
			)

			try visit(typeParameter, enumContext)
		}

		let enumType = EnumType(name: expr.nameToken.lexeme, cases: [], typeContext: typeContext)

		enumContext.defineVariable(named: "self", as: .selfVar(.enumType(enumType)), at: expr.location)

		var index = 0
		for decl in expr.body.decls {
			if let kase = decl as? EnumCaseDecl {
				for type in kase.attachedTypes {
					try type.accept(self, enumContext)
				}

				let enumCase = try EnumCase(
					type: enumType,
					name: kase.nameToken.lexeme,
					index: index,
					attachedTypes: kase.attachedTypes.map {
						try context.get($0).asType(in: context)
					}
				)

				index += 1
				enumType.cases.append(enumCase)
				context.extend(kase, with: .type(.enumCase(enumCase)))
			} else {
				try decl.accept(self, enumContext)
			}
		}

		// Let this enum be referred to by name
		context.defineVariable(named: enumType.name, as: .enumType(enumType), at: expr.location)
		context.extend(expr, with: .type(.enumType(enumType)))
	}

	public func visit(_: EnumCaseDeclSyntax, _: Context) throws {
		// Handled by EnumDeclSyntax
	}

	public func visit(_ expr: MatchStatementSyntax, _ context: Context) throws {
		try expr.target.accept(self, context)

		let matchContext = MatchContext(
			target: context[expr.target]?.asType(in: context) ?? .typeVar(context.freshTypeVariable("\(expr.description)")),
			current: expr
		)

		let context = context.withMatchContext(matchContext)

		try inferPattern(from: expr.target, in: context)

		for kase in expr.cases {
			matchContext.current = kase
			try kase.accept(self, context)
		}

		context.extend(expr, with: .type(.void))
	}

	public func visit(_ expr: CaseStmtSyntax, _ context: Context) throws {
		if let patternSyntax = expr.patternSyntax {
			try inferPattern(from: patternSyntax, in: context)
		}

		for stmt in expr.body {
			try stmt.accept(self, context)
		}

		context.extend(expr, with: .type(.void))
	}

	public func visit(_: EnumMemberExprSyntax, _: Context) throws {}

	public func visit(_ expr: InterpolatedStringExprSyntax, _ context: Context) throws {
		for case let .expr(interpolation) in expr.segments {
			try interpolation.expr.accept(self, context)
		}

		context.extend(expr, with: .type(.base(.string)))
	}

	public func visit(_ expr: ForStmtSyntax, _ context: Context) throws {
		let bodyContext = context.childContext()

		// Visit the sequence so we can get its type
		try expr.sequence.accept(self, context)
		let sequenceType = try context.get(expr.sequence)

		// Get the builtin iterable protocol
		guard let iterable = context.lookupVariable(named: "Iterable") else {
			throw InferencerError.cannotInfer("Could not find builtin Iterable protocol")
		}

		context.constraints.add(TypeConformanceConstraint(type: sequenceType, conformsTo: .type(iterable), location: expr.location))

		guard let expectedElementType = genericParameter(for: sequenceType.asType(in: context), named: "Element", in: context) else {
			throw InferencerError.parametersNotAvailable("Could not determine Element type of \(sequenceType)")
		}

		try bodyContext.expecting(expectedElementType) {
			try inferPattern(from: expr.element, in: bodyContext)
		}

		let elementType = try bodyContext.get(expr.element)
		context.constraints.add(.equality(.type(expectedElementType), elementType, at: expr.element.location))

		try expr.body.accept(self, bodyContext)

		context.extend(expr, with: .type(.void))
	}

	// GENERATOR_INSERTION

	func genericParameter(for type: InferenceType, named name: String, in context: InferenceContext) -> InferenceType? {
		switch type {
		case .structType(let structType):
			return structType.context.lookupVariable(named: name)
		case .structInstance(let instance):
			return instance.relatedType(named: name) ?? instance.type.context.lookupVariable(named: name)
		case .enumType(let enumType):
			if let typeVar = enumType.typeContext.typeParameters.first(where: { $0.name == name }) {
				return .typeVar(typeVar)
			}
		case .enumCase(let enumCase):
			if let typeVar = enumCase.type.typeContext.typeParameters.first(where: { $0.name == name }) {
				return .typeVar(typeVar)
			}
		default:
			()
		}

		return nil
	}
}
