//
//  ClassDeclSyntax.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
public struct ClassDeclSyntax: Decl, Syntax {
	public let start: Token
	public let end: Token
	public var name: IdentifierSyntax
	public var body: BlockStmtSyntax

	public func accept<Visitor: ASTVisitor>(
		_ visitor: Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
