//
//  CallExprSyntax.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct CallExprSyntax: Syntax, Expr {
	public let start: Token
	public let end: Token
	public let callee: any Expr
	public let arguments: ArgumentListSyntax

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
