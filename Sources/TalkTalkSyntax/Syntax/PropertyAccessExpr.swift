//
//  PropertyAccessExpr.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
public struct PropertyAccessExpr: Expr, Syntax {
	public let start: Token
	public let end: Token

	public var receiver: any Expr
	public var property: IdentifierSyntax

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
