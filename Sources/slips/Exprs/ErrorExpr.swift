//
//  ErrorExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct ErrorExpr: Expr {
	var message: String

	public func accept<V: Visitor>(_ visitor: V) -> V.Value {
		visitor.visit(self)
	}
}
