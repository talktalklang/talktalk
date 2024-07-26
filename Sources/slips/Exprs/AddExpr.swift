//
//  AddExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct AddExpr: Expr {
	let lhs: any Expr
	let rhs: any Expr

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
