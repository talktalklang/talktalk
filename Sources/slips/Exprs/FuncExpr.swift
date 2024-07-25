//
//  FuncExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

public struct FuncExpr: Expr {
	public let params: ParamsExpr
	public let body: any Expr

	public func accept<V>(_ visitor: V, _ scope: Scope) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
