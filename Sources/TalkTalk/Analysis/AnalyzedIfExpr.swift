//
//  AnalyzedIfExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct AnalyzedIfExpr: AnalyzedExpr, IfExpr {
	public var type: ValueType
	let expr: IfExpr

	public var conditionAnalyzed: any AnalyzedExpr
	public var consequenceAnalyzed: any AnalyzedExpr
	public var alternativeAnalyzed: any AnalyzedExpr

	public var condition: any Expr { expr.condition }
	public var consequence: any Expr { expr.consequence }
	public var alternative: any Expr { expr.alternative }

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor {
		visitor.visit(self, scope)
	}
}
