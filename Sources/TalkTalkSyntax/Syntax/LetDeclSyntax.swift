//
//  LetDeclSyntax.swift
//
//
//  Created by Pat Nakajima on 7/16/24.
//
public struct LetDeclSyntax: Decl, Stmt, Syntax, VarLetDecl {
	public let start: Token
	public let end: Token
	public var variable: IdentifierSyntax
	public var typeDecl: TypeDeclSyntax?
	public var expr: (any Expr)?

	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
		hasher.combine(variable)
		hasher.combine(typeDecl)
		hasher.combine(expr?.hashValue)
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
