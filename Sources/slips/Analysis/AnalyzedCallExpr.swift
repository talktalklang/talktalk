//
//  AnalyzedCallExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct AnalyzedCallExpr: AnalyzedExpr, CallExpr {
	public let type: ValueType
	let expr: CallExpr

	public var calleeAnalyzed: any AnalyzedExpr
	public var argsAnalyzed: [any AnalyzedExpr]

	public var callee: any Expr { expr.callee }
	public var args: [any Expr] { expr.args }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}
}
