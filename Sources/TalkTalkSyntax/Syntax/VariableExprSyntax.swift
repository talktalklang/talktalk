//
//  VariableExprSyntax.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct VariableExprSyntax: Syntax, Expr {
	public let start: Token
	public let end: Token
	public let name: IdentifierSyntax

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
