//
//  AddExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct AddExpr: Expr {
	let operands: [any Expr]

	public func accept<V>(_ visitor: V) -> V.Value where V: Visitor {
		visitor.visit(self)
	}
}
