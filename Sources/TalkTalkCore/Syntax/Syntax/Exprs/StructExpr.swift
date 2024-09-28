//
//  StructExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public protocol StructExpr: Expr {
	var structToken: Token { get }
	var name: String? { get }
	var body: any DeclBlock { get }
	var typeParameters: [TypeExprSyntax] { get }
}

public struct StructExprSyntax: StructExpr {
	public var id: SyntaxID
	public var structToken: Token
	public var name: String?
	public var typeParameters: [TypeExprSyntax]
	public var body: any DeclBlock
	public var location: SourceLocation
	public var children: [any Syntax] { [body] }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
