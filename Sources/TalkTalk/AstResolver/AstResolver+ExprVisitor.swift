//
//  AstResolver+ExprVisitor.swift
//
//
//  Created by Pat Nakajima on 6/29/24.
//

extension AstResolver: ExprVisitor {
	mutating func visit(_ expr: BinaryExpr) throws {
		try resolve(expr.lhs)
		try resolve(expr.rhs)
	}

	mutating func visit(_ expr: CallExpr) throws {
		try resolve(expr.callee)

		for argument in expr.arguments {
			try resolve(argument)
		}
	}

	mutating func visit(_ expr: GroupingExpr) throws {
		try resolve(expr.expr)
	}

	mutating func visit(_: LiteralExpr) throws {
		// Literals don't mention any variables
	}

	mutating func visit(_ expr: LogicExpr) throws {
		try resolve(expr.lhs)
		try resolve(expr.rhs)
	}

	mutating func visit(_ expr: UnaryExpr) throws {
		try resolve(expr.expr)
	}

	mutating func visit(_ expr: VariableExpr) throws {
		if let scope = scopes.last, scope.get(expr.name.lexeme) == .declared {
			TalkTalk.error("Can't read local variable in its own init", token: expr.name)
		}

		resolveLocal(expr: expr, name: expr.name)
	}

	mutating func visit(_ expr: AssignExpr) throws {
		try resolve(expr.value)
		resolveLocal(expr: expr, name: expr.name)
	}
}
