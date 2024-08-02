//
//  AnalyzedReturnExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/31/24.
//

import TalkTalkSyntax

public struct AnalyzedReturnExpr: AnalyzedExpr, ReturnExpr {
	public var type: ValueType
	let expr: any ReturnExpr

	public var value: (any Expr)? { expr.value }
	public var location: SourceLocation { expr.location }

	public var valueAnalyzed: (any AnalyzedExpr)?

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}