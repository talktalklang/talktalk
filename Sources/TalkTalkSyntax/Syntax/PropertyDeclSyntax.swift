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

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
		hasher.combine(typeDecl)
		hasher.combine(value?.hashValue)
	}

	public func accept<Visitor: ASTVisitor>(_ visitor: Visitor, context: Visitor.Context) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
