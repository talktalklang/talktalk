//
//  AnalyzedWhileExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

import TalkTalkSyntax

public struct AnalyzedWhileExpr: WhileExpr, AnalyzedExpr {
	public var type: ValueType
	let expr: WhileExpr

	public var conditionAnalyzed: any AnalyzedExpr
	public var bodyAnalyzed: AnalyzedBlockExpr

	public var condition: any Expr { expr.condition }
	public var body: any BlockExpr { expr.body }
	public var location: SourceLocation { expr.location }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
}
