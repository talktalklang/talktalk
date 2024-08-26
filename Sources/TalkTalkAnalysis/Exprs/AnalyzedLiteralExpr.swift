//
//  AnalyzedLiteralExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedLiteralExpr: AnalyzedExpr, LiteralExpr {
	public let typeID: TypeID
	public let wrapped: LiteralExprSyntax
	public var analyzedChildren: [any AnalyzedSyntax] { [] }
	public let environment: Environment

	public var value: LiteralValue { wrapped.value }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
