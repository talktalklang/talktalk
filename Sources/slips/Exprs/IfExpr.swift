//
//  IfExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct IfExpr: Expr {
	public let condition: any Expr
	public let consequence: any Expr
	public let alternative: any Expr

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
