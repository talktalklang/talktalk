//
//  StructExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public protocol StructExpr: Expr {
	var name: String? { get }
	var body: any DeclBlockExpr { get }
}

public struct StructExprSyntax: StructExpr {
	public var name: String?
	public var body: any DeclBlockExpr
	public var location: SourceLocation

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V : Visitor {
		visitor.visit(self, scope)
	}
}
