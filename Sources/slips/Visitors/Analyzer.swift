//
//  Analyzer.swift
//  Slips
//
//  Created by Pat Nakajima on 7/26/24.
//

public struct Analyzer: Visitor {
	public class Environment {
		var locals: [String: any AnalyzedExpr]

		public init() {
			self.locals = [:]
		}
	}

	public typealias Context = Environment
	public typealias Value = any AnalyzedExpr

	public init() {}

	public func visit(_: any CallExpr, _: Environment) -> any AnalyzedExpr {
		AnalyzedErrorExpr(type: .error, message: "TODO")
	}

	public func visit(_ expr: any DefExpr, _ context: Environment) -> any AnalyzedExpr {
		let value = expr.value.accept(self, context)

		context.locals[expr.name.lexeme] = value

		return AnalyzedDefExpr(type: value.type, expr: expr)
	}

	public func visit(_: any ErrorExpr, _: Environment) -> any AnalyzedExpr {
		AnalyzedErrorExpr(type: .error, message: "TODO")
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
		if let value = context.locals[expr.name] {
			return AnalyzedVarExpr(type: value.type, expr: expr)
		}

		return AnalyzedErrorExpr(type: .error, message: "Undefined variable: \(expr.name)")
	}

	public func visit(_ expr: any AddExpr, _: Environment) -> any AnalyzedExpr {
		AnalyzedAddExpr(expr: expr)
	}

	public func visit(_ expr: any IfExpr, _ context: Environment) -> any AnalyzedExpr {
		// TODO: Error if the branches don't match or condition isn't a bool
		AnalyzedIfExpr(type: expr.consequence.accept(self, context).type, expr: expr)
	}

	public func visit(_ expr: any FuncExpr, _ context: Environment) -> any AnalyzedExpr {
		var lastReturn: (any AnalyzedExpr)? = nil

		for bodyExpr in expr.body {
			lastReturn = bodyExpr.accept(self, context)
		}

		return AnalyzedFuncExpr(type: .function(lastReturn?.type ?? .void, expr.params.names), expr: expr)
	}

	public func visit(_ expr: any ParamsExpr, _: Environment) -> any AnalyzedExpr {
		AnalyzedParamsExpr(type: .void, expr: expr)
	}
}
