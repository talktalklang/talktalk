//
//  ArrayLiteralSyntax.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
public struct ArrayLiteralSyntax: Expr, Syntax {
	public var start: Token
	public var end: Token
	public var elements: ArgumentListSyntax

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
