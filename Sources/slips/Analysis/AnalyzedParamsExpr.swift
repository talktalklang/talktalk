//
//  AnalyzedParamsExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

public struct AnalyzedParamsExpr: AnalyzedExpr, ParamsExpr {
	public let type: ValueType
	let expr: ParamsExpr

	public var names: [String] { expr.names }

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
