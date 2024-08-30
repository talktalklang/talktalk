//
//  Inferencer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import TalkTalkSyntax

struct InferenceVisitor: Visitor {
	typealias Context = InferenceContext
	typealias Value = Void

	func infer(_ syntax: [any Syntax]) -> InferenceContext {
		let context = InferenceContext(
			parent: nil,
			environment: Environment(),
			constraints: Constraints()
		)

		for syntax in syntax {
			do {
				_ = try syntax.accept(self, context)
			} catch {
				context.addError(.unknownError(error.localizedDescription))
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

		let funcType = InferenceResult.scheme(
			Scheme(
				name: expr.name?.lexeme,
				variables: variables,
				type: .function(
					expr.params.params.map { childContext[$0]!.asType! },
					returns.first?.asType ?? childContext[expr.body]?.asType ?? .void
				)
			)
		)

		context.extend(expr, with: funcType)

		if let name = expr.name?.lexeme {
			context.namedVariables[name] = funcType.asType(in: context)
			childContext.namedVariables[name] = funcType.asType(in: context)
		}
	}

	func handleVarLet(_ expr: any VarLetDecl, _ context: InferenceContext) throws {
		try expr.typeExpr?.accept(self, context)
		try expr.value?.accept(self, context)

		let typeExpr: InferenceResult? = if let typeExpr = expr.typeExpr { context[typeExpr] } else { nil }
		let value: InferenceResult? = if let value = expr.value { context[value] } else { nil }

		var type: InferenceResult

		switch (typeExpr, value) {
		case let (typeExpr, value) where typeExpr != nil && value != nil:
			type = typeExpr!
			context.log("\(expr.description.components(separatedBy: .newlines)[0]) \(type) == \(value!)", prefix: " @ ")
			context.constraints.add(.equality(typeExpr!, value!, at: expr.location))
		case let (typeExpr, nil) where typeExpr != nil:
			type = typeExpr!
			context.log("\(expr.description.components(separatedBy: .newlines)[0]), already has type specified: \(type)", prefix: " @ ")
		case let (nil, value) where value != nil:
			type = value!
			context.log("\(expr.description.components(separatedBy: .newlines)[0]) \(type) == \(value!)", prefix: " @ ")
		default:
			let typeVar: InferenceType = context.freshTypeVariable(expr.name + " [decl]", file: #file, line: #line)
			type = .type(typeVar)
			context.log("\(expr.description.components(separatedBy: .newlines)[0]) \(type) == \(typeVar)", prefix: " @ ")
		}

		context.namedVariables[expr.name] = type.asType(in: context)
		context.extend(expr, with: type)
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

		if context[expr.receiver] != context[expr.value] {
			context.constraints.add(
				.equality(context[expr.receiver]!, context[expr.value]!, at: expr.location)
			)
		}

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
		} else {
			context.addError(.undefinedVariable(expr.name), to: expr)
		}
	}

	func visit(_ expr: UnaryExprSyntax, _ context: InferenceContext) throws {
		try expr.expr.accept(self, context)
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
		fatalError("TODO")
	}

	func visit(_ expr: WhileStmtSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: BlockStmtSyntax, _ context: InferenceContext) throws {
		for stmt in expr.stmts {
			try stmt.accept(self, context)
		}

		if let lastStmt = expr.stmts.last, let result = context[lastStmt] {
			context.extend(expr, with: result)
		}
	}

	func visit(_ expr: FuncExprSyntax, _ context: InferenceContext) throws {
		try handleFuncLike(expr, context)
	}

	func visit(_ expr: ParamsExprSyntax, _ context: InferenceContext) throws {
		for param in expr.params {
			try param.accept(self, context)
		}
	}

	func visit(_ expr: ParamSyntax, _ context: InferenceContext) throws {
		var type: InferenceType

		if let typeExpr = expr.type {
			type = context.lookupVariable(named: typeExpr.identifier.lexeme)!
		} else {
			type = .typeVar(context.freshTypeVariable(expr.name, file: #file, line: #line))
		}

		context.namedVariables[expr.name] = type
		context.extend(expr, with: .type(type))
	}

	func visit(_ expr: GenericParamsSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: CallArgument, _ context: InferenceContext) throws {
		try expr.value.accept(self, context)
		context.extend(expr, with: context[expr.value]!)
	}

	func visit(_ expr: StructExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: DeclBlockSyntax, _ context: InferenceContext) throws {
		for decl in expr.decls {
			try decl.accept(self, context)
		}
	}

	func visit(_ expr: VarDeclSyntax, _ context: InferenceContext) throws {
		try handleVarLet(expr, context)
	}

	func visit(_ expr: LetDeclSyntax, _ context: InferenceContext) throws {
		try handleVarLet(expr, context)
	}

	func visit(_ expr: ParseErrorSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: MemberExprSyntax, _ context: InferenceContext) throws {
		try expr.receiver.accept(self, context)
		let returns: InferenceType

		if expr.receiver.description.contains("wrapper.middle.inner") {
			
		}

		switch context[expr.receiver] {
		case let .type(.structInstance(receiver)):
			returns = receiver.member(named: expr.property)!
		case let .type(.structType(structType)):
			returns = structType.member(named: expr.property)!.asType(in: context)
		default:
			returns = .typeVar(context.freshTypeVariable(expr.description, file: #file, line: #line))
//			returns = .member(context[expr.receiver]!.asType(in: context), expr.property)
		}

		context.constraints.add(
			MemberConstraint(
				receiver: context[expr.receiver]!,
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
		fatalError("TODO")
	}

	func visit(_ expr: TypeExprSyntax, _ context: InferenceContext) throws {
		let type: InferenceType = switch expr.identifier.lexeme {
		case "int":
			.base(.int)
		case "String":
			.base(.string)
		case "bool":
			.base(.bool)
		default:
			context.lookupVariable(named: expr.identifier.lexeme)!
		}

		context.extend(expr, with: .type(type))
	}

	func visit(_ expr: ExprStmtSyntax, _ context: InferenceContext) throws {
		try expr.expr.accept(self, context)
		context.extend(expr, with: context[expr.expr]!)
	}

	func visit(_ expr: IfStmtSyntax, _ context: InferenceContext) throws {
		try expr.condition.accept(self, context)
		try expr.consequence.accept(self, context)
		try expr.alternative?.accept(self, context)
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
			let typeVar: TypeVariable = structContext.freshTypeVariable("\(structType).\(typeParameter.identifier.lexeme)", file: #file, line: #line)

			typeContext.typeParameters.append(
				typeVar
			)

			// Add this type to the struct's named variables for resolution
			structContext.namedVariables[typeParameter.identifier.lexeme] = .typeVar(typeVar)

			try visit(typeParameter, structContext)
		}

		let structInferenceType = InferenceType.structType(structType)

		// Make this type available by name outside its own context
		context.namedVariables[expr.name] = structInferenceType

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
		fatalError("TODO")
	}

	func visit(_ expr: SubscriptExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: DictionaryLiteralExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: DictionaryElementExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
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
		fatalError("TODO")
	}

	func visit(_ expr: FuncSignatureDeclSyntax, _ context: Context) throws {
		#warning("Generated by Dev/generate-type.rb")
		fatalError("TODO")
	}

	// GENERATOR_INSERTION
}
