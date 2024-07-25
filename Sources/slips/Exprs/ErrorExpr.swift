//
//  ErrorExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct ErrorExpr: Expr {
	var message: String

	public func accept<V: Visitor>(_ visitor: V, _ scope: Scope) -> V.Value {
		visitor.visit(self, scope)
	}
}
