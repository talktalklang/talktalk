//
//  CallExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct CallExpr: Expr {
	public let op: Token
	public let args: [Expr]

	public func accept<V: Visitor>(_ visitor: V, _ scope: Scope) -> V.Value {
		visitor.visit(self, scope)
	}
}
