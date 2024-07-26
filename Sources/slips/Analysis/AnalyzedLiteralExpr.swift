//
//  AnalyzedLiteralExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct AnalyzedLiteralExpr: AnalyzedExpr, LiteralExpr {
	public let type: ValueType
	let expr: LiteralExpr

	public var value: Value { expr.value }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}
}
