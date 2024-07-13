//
//  BinaryExprSyntax.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct BinaryExprSyntax: Syntax, Expr {
	public let lhs: any Expr
	public let op: BinaryOperatorSyntax
	public let rhs: any Expr

	public let start: Token
	public let end: Token

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
