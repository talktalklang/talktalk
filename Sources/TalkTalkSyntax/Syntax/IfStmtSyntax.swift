//
//  IfStmtSyntax.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct IfStmtSyntax: Syntax, Stmt {
	public let start: Token
	public let end: Token
	public var condition: any Expr
	public var body: BlockStmtSyntax

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
