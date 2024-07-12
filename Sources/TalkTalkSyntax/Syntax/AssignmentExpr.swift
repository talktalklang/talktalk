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

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: inout Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: &context)
	}
}
