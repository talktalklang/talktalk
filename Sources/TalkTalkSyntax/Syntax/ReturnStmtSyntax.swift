//
//  ReturnStmtSyntax.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct ReturnStmtSyntax: Syntax, Stmt {
	public let start: Token
	public let end: Token
	public var value: any Expr

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
