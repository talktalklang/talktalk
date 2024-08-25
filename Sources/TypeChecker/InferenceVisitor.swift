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
		let context = InferenceContext(environment: Environment())

		for syntax in syntax {
			do {
				try syntax.accept(self, context)
			} catch {
				context.addError(.unknownError(error))
			}
		}

		return context
	}

	func visit(_ expr: any CallExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
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
			context.environment.extend(expr, with: .type(.base(.int)))
		case .bool:
			context.environment.extend(expr, with: .type(.base(.bool)))
		case .string:
			context.environment.extend(expr, with: .type(.base(.string)))
		case .none:
			context.environment.extend(expr, with: .type(.base(.nope)))
		}
	}

	func visit(_ expr: any VarExpr, _ context: InferenceContext) throws {
		if let variable = context.environment.lookupVariable(named: expr.name) {
			context.environment.extend(expr, with: .type(variable))
		} else {
			context.addError(.undefinedVariable(expr.name))
		}
	}

	func visit(_ expr: any UnaryExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any BinaryExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
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
			context.environment.extend(expr, with: context.environment[stmt]!)
		} else {
			context.environment.extend(expr, with: .type(.void))
		}
	}

	func visit(_ expr: any FuncExpr, _ context: InferenceContext) throws {
		var variables: [TypeVariable] = []
		var params: [InferenceType] = []
		for param in expr.params.params {
			let typeVariable = context.freshVariable(param.name)
			variables.append(typeVariable)
			params.append(.variable(typeVariable))
			context.environment.extend(param, with: .type(.variable(typeVariable)))
		}

		try visit(expr.body, context)
		guard case let .type(bodyType) = context.environment[expr.body] else {
			fatalError("did not get body type")
		}

		let functionType = InferenceType.function(params, bodyType)
		let scheme = Scheme(variables: variables, type: functionType)

		context.environment.extend(expr, with: .scheme(scheme))
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
		fatalError("TODO")
	}

	func visit(_ expr: any StructExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any DeclBlock, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any VarDecl, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any LetDecl, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any ParseError, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any MemberExpr, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: any ReturnStmt, _ context: InferenceContext) throws {
		fatalError("TODO")
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
		context.environment.extend(expr, with: context.environment[expr.expr]!)
	}

	func visit(_ expr: any IfStmt, _ context: InferenceContext) throws {
		fatalError("TODO")
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
