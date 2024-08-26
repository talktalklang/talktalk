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
				try syntax.accept(self, context)
			} catch {
				context.addError(.unknownError(error.localizedDescription))
			}
		}

		return context
	}

	func handleVarLet(_ decl: any VarLetDecl, context: InferenceContext) throws {
		let typeVariable = context.freshTypeVariable(decl.name)

		if let value = decl.value {
			try value.accept(self, context)
			context.extend(decl, with: .type(.typeVar(typeVariable)))

			// Get the inferred type of the value from the environment
			switch context[value] {
			case let .type(valueType):
				context.unify(.typeVar(typeVariable), valueType)
			case let .scheme(scheme):
				let type = context.instantiate(scheme: scheme)
				context.unify(.typeVar(typeVariable), type)
			default:
				fatalError("need to figure this out")
			}
		}
	}

	// Visits

	func visit(_ expr: any CallExpr, _ context: InferenceContext) throws {
		try expr.callee.accept(self, context)

		// Create a separate child context for evaluating arguments (to prevent leaks)
		let childContext = context.childContext()

		// Extract the function type or instantiate if it's a scheme
		var functionType: InferenceType? = switch context[expr.callee] {
		case let .type(type):
			type
		case let .scheme(scheme):
			childContext.instantiate(scheme: scheme)
		default:
			nil
		}

		if let foundFunctionType = functionType {
			functionType = childContext.applySubstitutions(to: foundFunctionType)
		}

		guard case let .function(parameters, returns) = functionType else {
			context.extend(expr, with: .type(.error(.typeError("Callee not callable: \(functionType?.description ?? "nope")"))))
			return
		}

		if parameters.count != expr.args.count {
			context.extend(expr, with: .type(.error(.argumentError("Expected \(parameters.count) arguments, got \(expr.args.count)"))))
			return
		}

		// Infer and unify each argument's type with the corresponding parameter type
		for (argExpr, paramType) in zip(expr.args, parameters) {
			try argExpr.accept(self, childContext) // Infer the argument type

			if case let .type(argType) = childContext[argExpr] {
				context.unify(argType, paramType) // Unify argument type with the parameter type
			} else {
				context.extend(expr, with: .type(.error(.argumentError("Could not determine argument/parameter agreement"))))
			}
		}

		// Set the return type in the environment
		let finalReturns = context.applySubstitutions(to: returns)
		context.extend(expr, with: .type(finalReturns))
	}

	func visit(_ expr: any DefExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any IdentifierExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any LiteralExpr, _ context: InferenceContext) throws {
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

	func visit(_ expr: any VarExpr, _ context: InferenceContext) throws {
		if let variable = context.lookupVariable(named: expr.name) {
			context.extend(expr, with: .type(variable))
		} else {
			context.addError(.undefinedVariable(expr.name + ", ln: \(expr.location.line)"), to: expr)
		}
	}

	func visit(_ expr: any UnaryExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any BinaryExpr, _ context: InferenceContext) throws {
		try expr.lhs.accept(self, context)
		try expr.rhs.accept(self, context)

		guard case let .type(lhs) = context[expr.lhs] else {
			fatalError("did not get type for binary expr lhs")
		}

		guard case let .type(rhs) = context[expr.rhs] else {
			fatalError("did not get type for binary expr rhs")
		}

		context.unify(lhs, rhs)
		guard let constraint = context.constraints.map[.infixOperator(expr.op)]?[lhs] else {
			context.addError(.missingConstraint(lhs, .infixOperator(expr.op)), to: expr)
			return
		}

		let type = switch constraint.check(lhs, with: [rhs]) {
		case let .error(error):
			context.addError(error)
		case let .ok(returns):
			returns
		}

		context.extend(expr, with: .type(type))
	}

	func visit(_ expr: any IfExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any WhileStmt, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any BlockStmt, _ context: InferenceContext) throws {
		for stmt in expr.stmts {
			try stmt.accept(self, context)
		}

		if let stmt = expr.stmts.last {
			context.extend(expr, with: context[stmt]!)
		} else {
			context.extend(expr, with: .type(.void))
		}
	}

	func visit(_ expr: any FuncExpr, _ context: InferenceContext) throws {
		let childContext = context.childContext()

		// Create type variable for parameters and extend them to the environment
		// TODO: should we be creating a new context?
		var params: [InferenceType] = []
		for param in expr.params.params {
			let typeVariable = childContext.freshTypeVariable(param.name)
			params.append(.typeVar(typeVariable))
			childContext.extend(param, with: .type(.typeVar(typeVariable)))
		}

		// Create a temporary type variable for the function itself to allow for recursion
		let returning = InferenceType.typeVar(context.freshTypeVariable())
		var temporaryFn = InferenceType.function(params, returning)

		if let name = expr.name?.lexeme {
			let funcNameVar = context.freshTypeVariable(name)

			context.extend(expr, with: .type(.typeVar(funcNameVar)))
			context.unify(.typeVar(funcNameVar), temporaryFn)

			childContext.extend(expr, with: .type(temporaryFn))
			childContext.unify(.typeVar(funcNameVar), temporaryFn)

			temporaryFn = childContext.applySubstitutions(to: temporaryFn)
		}

		let returns = try childContext.trackReturns {
			try visit(expr.body, childContext)
		}

		// TODO: make sure returns agree
		guard case let .type(bodyType) = returns.first ?? childContext[expr.body] else {
			fatalError("did not get body type")
		}

		let functionType = InferenceType.function(params, bodyType)
		let scheme = Scheme(name: expr.name?.lexeme, variables: params.filter { childContext.isFreeVariable($0) }, type: functionType)

		context.bind(typeVar: context.freshTypeVariable(expr.name?.lexeme), to: functionType)
		context.extend(expr, with: .scheme(scheme))
	}

	func visit(_ expr: any ParamsExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any Param, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any GenericParams, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: CallArgument, _ context: InferenceContext) throws {
		try expr.value.accept(self, context)
		context.extend(expr, with: context[expr.value]!)
	}

	func visit(_ expr: any StructExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any DeclBlock, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any VarDecl, _ context: InferenceContext) throws {
		try handleVarLet(expr, context: context)
	}

	func visit(_ expr: any LetDecl, _ context: InferenceContext) throws {
		try handleVarLet(expr, context: context)
	}

	func visit(_ expr: any ParseError, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any MemberExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any ReturnStmt, _ context: InferenceContext) throws {
		if let value = expr.value {
			try value.accept(self, context)
			context.extend(expr, with: context[value]!)
			context.trackReturn(context[value]!)
		} else {
			context.extend(expr, with: .type(.void))
			context.trackReturn(.type(.void))
		}
	}

	func visit(_ expr: any InitDecl, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any ImportStmt, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any TypeExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any ExprStmt, _ context: InferenceContext) throws {
		try expr.expr.accept(self, context)
		context.extend(expr, with: context[expr.expr]!)
	}

	func visit(_ expr: any IfStmt, _ context: InferenceContext) throws {
		try expr.condition.accept(self, context)
		try expr.consequence.accept(self, context)
		try expr.alternative?.accept(self, context)

		context.extend(expr, with: .type(.void))
	}

	func visit(_ expr: any StructDecl, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any ArrayLiteralExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any SubscriptExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any DictionaryLiteralExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any DictionaryElementExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}
}
