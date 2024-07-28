//
//  Analyzer.swift
//  Slips
//
//  Created by Pat Nakajima on 7/26/24.
//

public struct Analyzer: Visitor {
	public typealias Context = Environment
	public typealias Value = any AnalyzedExpr

	public init() {}

	public static func analyze(_ exprs: [any Expr]) -> any AnalyzedExpr {
		let env = Environment()
		let analyzer = Analyzer()

		let mainExpr = FuncExprSyntax(params: ParamsExprSyntax(params: []), body: exprs, i: 0, name: "main")
		return analyzer.visit(mainExpr, env)
	}

	public func visit(_ expr: any CallExpr, _ context: Environment) -> any AnalyzedExpr {
		let callee = expr.callee.accept(self, context)

		// TODO: Update environment with the types getting passed to these args.
		let args = expr.args.map { $0.accept(self, context) }

		guard case let .function(_, t, _) = callee.type else {
			return AnalyzedErrorExpr(type: .error, message: "callee not callable")
		}

		return AnalyzedCallExpr(
			type: t,
			expr: expr,
			calleeAnalyzed: callee,
			argsAnalyzed: args
		)
	}

	public func visit(_ expr: any DefExpr, _ context: Environment) -> any AnalyzedExpr {
		let value = expr.value.accept(self, context)

		context.define(local: expr.name.lexeme, as: value)

		return AnalyzedDefExpr(type: value.type, expr: expr, valueAnalyzed: value)
	}

	public func visit(_ expr: any ErrorExpr, _: Environment) -> any AnalyzedExpr {
		AnalyzedErrorExpr(type: .error, message: expr.message)
	}

	public func visit(_ expr: any LiteralExpr, _: Environment) -> any AnalyzedExpr {
		switch expr.value {
		case .int:
			AnalyzedLiteralExpr(type: .int, expr: expr)
		case .bool:
			AnalyzedLiteralExpr(type: .bool, expr: expr)
		case .none:
			AnalyzedLiteralExpr(type: .none, expr: expr)
		case let .error(string):
			AnalyzedErrorExpr(type: .error, message: string)
		case .fn:
			fatalError("Unreachable")
		}
	}

	public func visit(_ expr: any VarExpr, _ context: Environment) -> any AnalyzedExpr {
		if let binding = context.lookup(expr.name) {
			return AnalyzedVarExpr(type: binding.expr.type, expr: expr)
		}

		return AnalyzedErrorExpr(type: .error, message: "Undefined variable: \(expr.name)")
	}

	public func visit(_ expr: any AddExpr, _ env: Environment) -> any AnalyzedExpr {
		let lhs = expr.lhs.accept(self, env)
		let rhs = expr.rhs.accept(self, env)

		infer(lhs, rhs, as: .int, in: env)

		return AnalyzedAddExpr(type: .int, expr: expr, lhsAnalyzed: lhs, rhsAnalyzed: rhs)
	}

	public func visit(_ expr: any IfExpr, _ context: Environment) -> any AnalyzedExpr {
		// TODO: Error if the branches don't match or condition isn't a bool
		AnalyzedIfExpr(
			type: expr.consequence.accept(self, context).type,
			expr: expr,
			conditionAnalyzed: expr.condition.accept(self, context),
			consequenceAnalyzed: expr.consequence.accept(self, context),
			alternativeAnalyzed: expr.alternative.accept(self, context)
		)
	}

	public func visit(_ expr: any FuncExpr, _ env: Environment) -> any AnalyzedExpr {
		let innerEnvironment = env.add()

		// Define our parameters in the environment so they're declared in the body. They're
		// just placeholders for now.
		var params = visit(expr.params, env) as! AnalyzedParamsExpr
		for param in params.paramsAnalyzed {
			innerEnvironment.define(local: param.name, as: param)
		}

		// Visit the body with the innerEnvironment, finding captures as we go.
		var bodyAnalyzed: [any AnalyzedExpr] = []
		for bodyExpr in expr.body {
			bodyAnalyzed.append(bodyExpr.accept(self, innerEnvironment))
		}

		// See if we can infer any types for our params from the environment after the body
		// has been visited.
		params.infer(from: innerEnvironment)

		return AnalyzedFuncExpr(
			type: .function(expr.name, bodyAnalyzed.last?.type ?? .void, params),
			expr: expr,
			analyzedParams: params,
			bodyAnalyzed: bodyAnalyzed,
			returnsAnalyzed: bodyAnalyzed.last,
			environment: innerEnvironment
		)
	}

	public func visit(_ expr: any ParamsExpr, _: Environment) -> any AnalyzedExpr {
		AnalyzedParamsExpr(
			type: .void,
			expr: expr,
			paramsAnalyzed: expr.params.enumerated().map { i, param in
				AnalyzedParam(name: param.name, type: .placeholder(i))
			}
		)
	}

	public func visit(_ expr: any Param, _ context: Environment) -> any AnalyzedExpr {
		AnalyzedParam(name: expr.name, type: .placeholder(1))
	}

	private func infer(_ exprs: (any AnalyzedExpr)..., as type: ValueType, in env: Environment) {
		if case .placeholder(_) = type { return }

		for expr in exprs {
			if var expr = expr as? AnalyzedVarExpr {
				expr.type = type
				env.update(local: expr.name, as: type)
				if let capture = env.captures.first(where: { $0.name == expr.name }) {
					capture.binding.expr.type = type
					capture.binding.type = type
				}
			}
		}


	}
}
