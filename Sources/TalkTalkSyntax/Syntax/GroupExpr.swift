//
//  GroupExpr.swift
//
//
//  Created by Pat Nakajima on 7/9/24.
//
public struct GroupExpr: Expr, Syntax {
	public let start: Token
	public let end: Token
	public let expr: any Expr

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
		hasher.combine(expr)
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
