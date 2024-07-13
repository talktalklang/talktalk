//
//  PropertyDeclSyntax.swift
//
//
//  Created by Pat Nakajima on 7/12/24.
//
public struct PropertyDeclSyntax: Syntax, Decl {
	public let start: Token
	public let end: Token
	public var name: IdentifierSyntax
	public var typeDecl: TypeDeclSyntax
	public var value: (any Expr)?

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor, context: Visitor.Context) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
