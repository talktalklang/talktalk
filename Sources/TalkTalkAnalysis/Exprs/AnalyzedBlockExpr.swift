//
//  AnalyzedBlockExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

import TalkTalkSyntax

public struct AnalyzedBlockExpr: AnalyzedExpr, BlockExpr {
	public var type: ValueType
	let expr: any BlockExpr

	public var exprsAnalyzed: [any AnalyzedExpr]
	public var exprs: [any Expr] { expr.exprs }

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V : AnalyzedVisitor {
		visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V : Visitor {
		visitor.visit(self, scope)
	}
}
