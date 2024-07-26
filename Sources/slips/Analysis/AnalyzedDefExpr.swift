//
//  DefExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct AnalyzedDefExpr: AnalyzedExpr, DefExpr {
	public let type: ValueType
	let expr: DefExpr

	public var name: Token { expr.name }
	public var value: any Expr { expr.value }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}
}
