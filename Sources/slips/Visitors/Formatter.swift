//
//  Formatter.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct Formatter: Visitor {
	public func visit(_ expr: CallExpr) -> String {
		"(\(expr.op.lexeme) \(expr.args.map { $0.accept(self) }.joined(separator: " "))"
	}

	public func visit(_ expr: DefExpr) -> String {
		"(def \(expr.name.lexeme) \(expr.expr.accept(self)))"
	}

	public func visit(_ expr: ErrorExpr) -> String {
		"Error: \(expr)"
	}

	public func visit(_ expr: LiteralExpr) -> String {
		switch expr.value {
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

	public func visit(_ expr: VarExpr) -> String {
		expr.name
	}

	public func visit(_ expr: AddExpr) -> String {
		"(+ \(expr.operands.map { $0.accept(self) }.joined(separator: " ")))"
	}

	public func visit(_ expr: IfExpr) -> String {
		"(if \(expr.condition.accept(self)) \(expr.consequence.accept(self)) \(expr.alternative.accept(self)))"
	}
}
