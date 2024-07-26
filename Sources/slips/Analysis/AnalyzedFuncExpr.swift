//
//  FuncExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

public struct AnalyzedFuncExpr: AnalyzedExpr, FuncExpr {
	public let type: ValueType
	let expr: FuncExpr

	public var params: ParamsExpr { expr.params }
	public var body: [any Expr] { expr.body }
	public var i: Int { expr.i }

	public var name: String {
		"_fn_\(params.names.joined(separator: "_"))_\(i)"
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
