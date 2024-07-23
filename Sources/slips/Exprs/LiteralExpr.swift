//
//  LiteralExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct LiteralExpr: Expr {
	let value: Value

	public func accept<V: Visitor>(_ visitor: V) -> V.Value {
		visitor.visit(self)
	}
}
