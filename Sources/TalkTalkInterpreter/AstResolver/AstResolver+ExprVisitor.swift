//
//  AstResolver+ExprVisitor.swift
//
//
//  Created by Pat Nakajima on 6/29/24.
//

enum ResolverError: Error {
	case topLevelReturn
}

extension AstResolver: ExprVisitor {
	mutating func visit(_ expr: LiteralExpr) throws {
		try resolve(expr)
	}

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

	mutating func visit(_ expr: LogicExpr) throws {
		try resolve(expr.lhs)
		try resolve(expr.rhs)
	}

	mutating func visit(_ expr: UnaryExpr) throws {
		try resolve(expr.expr)
	}

	mutating func visit(_ expr: VariableExpr) throws {
		resolveLocal(expr: expr, name: expr.name)
	}

	mutating func visit(_ expr: AssignExpr) throws {
		try resolve(expr.value)
		resolveLocal(expr: expr, name: expr.name)
	}

	mutating func visit(_ expr: GetExpr) throws {
		try resolve(expr.receiver)
	}

	mutating func visit(_ expr: SetExpr) throws {
		try resolve(expr.value)
		try resolve(expr.receiver)
	}

	mutating func visit(_ expr: SelfExpr) throws {
		resolveLocal(expr: expr, name: expr.token)
	}
}
