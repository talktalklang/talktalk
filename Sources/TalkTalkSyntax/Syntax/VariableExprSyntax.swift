//
//  VariableExprSyntax.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct VariableExprSyntax: Syntax, Expr {
	public let position: Int
	public let length: Int
	public let name: IdentifierSyntax

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
