//
//  IfExprSyntax.swift
//  
//
//  Created by Pat Nakajima on 7/14/24.
//
public struct IfExprSyntax: Syntax, Expr {
	public let start: Token
	public let end: Token
	public var condition: any Expr
	public var thenBlock: BlockStmtSyntax
	public var elseBlock: BlockStmtSyntax

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
