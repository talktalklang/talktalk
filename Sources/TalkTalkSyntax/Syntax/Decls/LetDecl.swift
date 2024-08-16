//
//  LetDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public protocol LetDecl: Decl {
	var token: Token { get }
	var name: String { get }
	var typeDecl: String? { get }
	var typeDeclToken: Token? { get }
	var value: (any Expr)? { get }
}

public struct LetDeclSyntax: LetDecl {
	public var token: Token
	public var name: String
	public var typeDecl: String?
	public var typeDeclToken: Token?
	public var value: (any Expr)?

	public var location: SourceLocation
	public var children: [any Syntax] {
		if let value { [value] } else { [] }
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
}
