//
//  AnalyzedUnaryExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkSyntax

public struct AnalyzedUnaryExpr: AnalyzedExpr, UnaryExpr {
	public var type: ValueType
	public var exprAnalyzed: any AnalyzedExpr

	let wrapped: UnaryExpr

	public var location: SourceLocation { wrapped.location }
	public var op: Token.Kind { wrapped.op }
	public var expr: any Expr { wrapped.expr }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
