//
//  IdentifierExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

public protocol IdentifierExpr: Expr {
	var name: String { get }
}

public struct IdentifierExprSyntax: IdentifierExpr {
	public var name: String
	public var location: SourceLocation

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}

	public var children: [any Syntax] { [] }
}
