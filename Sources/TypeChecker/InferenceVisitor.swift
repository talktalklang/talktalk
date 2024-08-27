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

	func handleVarLet(_ expr: any VarLetDecl, _ context: InferenceContext) throws {
		try expr.typeExpr?.accept(self, context)
		try expr.value?.accept(self, context)

		let typeExpr: InferenceResult? = if let typeExpr = expr.typeExpr { context[typeExpr] } else { nil }
		let value: InferenceResult? = if let value = expr.value { context[value] } else { nil }

		let typeVar = context.freshTypeVariable(expr.name)

		switch (typeExpr, value) {
		case let (typeExpr, value) where typeExpr != nil && value != nil:
			context.constraints.add(.equality(typeExpr!, value!, at: expr.location))
			context.constraints.add(.equality(.type(.typeVar(typeVar)), value!, at: expr.location))
			context.constraints.add(.equality(.type(.typeVar(typeVar)), typeExpr!, at: expr.location))
		case let (typeExpr, nil) where typeExpr != nil:
			context.constraints.add(.equality(.type(.typeVar(typeVar)), typeExpr!, at: expr.location))
		case let (nil, value) where value != nil:
			context.constraints.add(.equality(.type(.typeVar(typeVar)), value!, at: expr.location))
		default:
			()
		}

		context.extend(expr, with: .type(.typeVar(typeVar)))
	}

	// Visits

	func visit(_ expr: CallExprSyntax, _ context: InferenceContext) throws {
		try expr.callee.accept(self, context)
		for arg in expr.args {
			try arg.accept(self, context)
		}

		let returns = context.freshTypeVariable()

		let callee = context[expr.callee]!
		let args = expr.args.map { context[$0]! }

		context.constraints.add(
			.call(callee, args, returns: .typeVar(returns), at: expr.location)
		)

		context.extend(expr, with: .type(.typeVar(returns)))
	}

	func visit(_ expr: DefExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
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
			context.extend(expr, with: .type(defined))
		} else {
			context.addError(.undefinedVariable(expr.name), to: expr)
		}
	}

	func visit(_ expr: UnaryExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
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

		let returns = context.freshTypeVariable()

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
		let childContext = context.childContext()

		try expr.params.accept(self, childContext)

		let returns = try childContext.trackReturns {
			try expr.body.accept(self, childContext)
		}

		let funcType = InferenceResult.scheme(
			Scheme(
				name: expr.name?.lexeme,
				variables: expr.params.params.compactMap {
					if let type = childContext[$0]?.asType(in: context),
						 childContext.isFreeVariable(type) {
						return type
					}

					return nil
				},
				type: .function(
					expr.params.params.map { childContext[$0]!.asType! },
					returns.first?.asType ?? childContext[expr.body]?.asType ?? .void
				)
			)
		)

		context.extend(expr, with: funcType)

		if let name = expr.name?.lexeme {
			let typeVar = context.freshTypeVariable(name)
			context.constraints.add(VariableConstraint(typeVar: .typeVar(typeVar), value: funcType))
			childContext.constraints.add(VariableConstraint(typeVar: .typeVar(typeVar), value: funcType))
		}
	}

	func visit(_ expr: ParamsExprSyntax, _ context: InferenceContext) throws {
		for param in expr.params {
			try param.accept(self, context)
		}
	}

	func visit(_ expr: ParamSyntax, _ context: InferenceContext) throws {
		let typeVar = context.freshTypeVariable(expr.name)
		context.extend(expr, with: .type(.typeVar(typeVar)))
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
		fatalError("TODO")
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
		fatalError("TODO")
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
		fatalError("TODO")
	}

	func visit(_ expr: ImportStmtSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: TypeExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
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
		fatalError("TODO")
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
		fatalError("TODO")
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
