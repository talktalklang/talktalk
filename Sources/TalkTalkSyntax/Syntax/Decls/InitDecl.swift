//
//  InitDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

public protocol InitDecl: Decl {
	var initToken: Token { get }
	var parameters: ParamsExpr { get }
	var body: any DeclBlock { get }
}

public struct InitDeclSyntax: InitDecl {
	public var initToken: Token
	public var parameters: ParamsExpr
	public var body: any DeclBlock

	public var location: SourceLocation
	public var children: [any Syntax] {
		[parameters, body]
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
}
