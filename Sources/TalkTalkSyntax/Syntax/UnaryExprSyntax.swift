///  UnaryExprSyntax.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct UnaryExprSyntax: Syntax, Expr {
	public let start: Token
	public let end: Token

	public let op: UnaryOperator
	public let rhs: any Expr

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
		hasher.combine(op)
		hasher.combine(rhs)
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
