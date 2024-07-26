//
//  FuncExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

public struct FuncExpr: Expr {
	public let params: ParamsExpr
	public let body: [any Expr]
	public let i: Int

	var name: String {
		"_fn_\(params.names.joined(separator: "_"))_\(i)"
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
