//
//  Formatter.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct Formatter: Visitor {
	public func visit(_ expr: CallExpr, _ scope: Scope) -> String {
		"(\(expr.op.lexeme) \(expr.args.map { $0.accept(self, scope) }.joined(separator: " "))"
	}

	public func visit(_ expr: DefExpr, _ scope: Scope) -> String {
		"(def \(expr.name.lexeme) \(expr.expr.accept(self, scope)))"
	}

	public func visit(_ expr: ErrorExpr, _: Scope) -> String {
		"Error: \(expr)"
	}

	public func visit(_ expr: LiteralExpr, _ scope: Scope) -> String {
		switch expr.value {
		case let .fn(closure):
			"fn: \(closure.funcExpr.body.accept(self, scope))"
		case let .bool(bool):
			"\(bool)"
		case let .int(int):
			"\(int)"
		case let .string(string):
			"'\(string)'"
		case .none:
			"none"
		case let .error(message):
			"Error: \(message)"
		}
	}

	public func visit(_ expr: VarExpr, _: Scope) -> String {
		expr.name
	}

	public func visit(_ expr: AddExpr, _ scope: Scope) -> String {
		"(+ \(expr.operands.map { $0.accept(self, scope) }.joined(separator: " ")))"
	}

	public func visit(_ expr: IfExpr, _ scope: Scope) -> String {
		"(if \(expr.condition.accept(self, scope)) \(expr.consequence.accept(self, scope)) \(expr.alternative.accept(self, scope)))"
	}

	public func visit(_ expr: FuncExpr, _ scope: Scope) -> String {
		"(\(visit(expr.params, scope)) in \(expr.body.accept(self, scope)))"
	}

	public func visit(_ expr: ParamsExpr, _: Scope) -> String {
		"\(expr.names.joined(separator: " "))"
	}
}
