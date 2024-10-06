//
//  InitDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

public protocol InitDecl: Decl {
	var initToken: Token { get }
	var params: ParamsExprSyntax { get }
	var body: BlockStmtSyntax { get }
}

public struct InitDeclSyntax: InitDecl {
	public var id: SyntaxID
	public var initToken: Token
	public var params: ParamsExprSyntax
	public var body: BlockStmtSyntax

	public var location: SourceLocation
	public var children: [any Syntax] {
		[params, body]
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
