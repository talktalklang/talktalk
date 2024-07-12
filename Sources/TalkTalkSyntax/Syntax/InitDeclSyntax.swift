//
//  InitDeclSyntax.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
public struct InitDeclSyntax: Decl, Syntax {
	public let start: Token
	public let end: Token

	public var parameters: ParameterListSyntax
	public var body: BlockStmtSyntax

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
