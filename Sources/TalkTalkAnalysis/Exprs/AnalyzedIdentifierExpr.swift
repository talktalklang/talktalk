//
//  AnalyzedIdentifierExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import TalkTalkSyntax

public struct AnalyzedIdentifierExpr: AnalyzedExpr, IdentifierExpr {
	public let typeID: TypeID

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public var wrapped: IdentifierExprSyntax
	public var analyzedChildren: [any AnalyzedSyntax] { [] }
	public var name: String { wrapped.name }
	public let environment: Environment

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: TalkTalkSyntax.Visitor {
		try visitor.visit(wrapped, scope)
	}
}
