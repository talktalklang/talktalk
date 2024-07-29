//
//  AnalyzedIfExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedIfExpr: AnalyzedExpr, IfExpr {
	public var type: ValueType
	let expr: IfExpr

	public var conditionAnalyzed: any AnalyzedExpr
	public var consequenceAnalyzed: AnalyzedBlockExpr
	public var alternativeAnalyzed: AnalyzedBlockExpr

	public var condition: any Expr { expr.condition }
	public var consequence: any BlockExpr { expr.consequence }
	public var alternative: any BlockExpr { expr.alternative }

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor {
		visitor.visit(self, scope)
	}
}
