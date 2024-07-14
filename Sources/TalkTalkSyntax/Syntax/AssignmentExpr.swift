//
//  AssignmentExpr.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct AssignmentExpr: Syntax, Expr {
	public let start: Token
	public let end: Token
	public let lhs: any Expr
	public let rhs: any Expr

	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
		hasher.combine(lhs)
		hasher.combine(rhs)
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
