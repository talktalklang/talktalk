//
//  Untitled.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct ExprStmtSyntax: Syntax, Stmt {
	public let start: Token
	public let end: Token
	public let expr: any Expr

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: inout Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: &context)
	}
}
