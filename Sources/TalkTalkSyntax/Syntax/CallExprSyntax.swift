//
//  CallExprSyntax.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct CallExprSyntax: Syntax, Expr {
	public let position: Int
	public let length: Int
	public let callee: any Expr
	public let arguments: ArgumentListSyntax

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
