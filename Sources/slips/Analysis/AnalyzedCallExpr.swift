//
//  AnalyzedCallExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct AnalyzedCallExpr: AnalyzedExpr, CallExpr {
	public let type: ValueType
	let expr: CallExpr

	public var op: Token { expr.op }
	public var args: [Expr] { expr.args }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}
}
