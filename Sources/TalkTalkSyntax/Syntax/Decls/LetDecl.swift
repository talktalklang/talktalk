//
//  LetDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public protocol LetDecl: Decl {
	var name: String { get }
	var typeDecl: String { get }
}

public struct LetDeclSyntax: VarDecl {
	public var name: String
	public var typeDecl: String
	public var location: SourceLocation
	public var children: [any Syntax] { [] }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
}
