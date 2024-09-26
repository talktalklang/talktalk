//
//  LetDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public protocol LetDecl: Decl, VarLetDecl {
	var token: Token { get }
	var name: String { get }
	var nameToken: Token { get }
	var isStatic: Bool { get }
	var typeExpr: TypeExprSyntax? { get }
	var value: (any Expr)? { get }
}

public struct LetDeclSyntax: LetDecl {
	public var id: SyntaxID
	public var token: Token
	public var name: String
	public var nameToken: Token
	public var isStatic: Bool
	public var modifiers: [Token]
	public var typeExpr: TypeExprSyntax?
	public var value: (any Expr)?

	public var location: SourceLocation
	public var children: [any Syntax] {
		if let value { [value] } else { [] }
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
