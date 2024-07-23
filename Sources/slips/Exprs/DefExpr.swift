//
//  DefExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct DefExpr: Expr {
	public let name: Token
	public let expr: any Expr

	public func accept<V: Visitor>(_ visitor: V) -> V.Value {
		visitor.visit(self)
	}
}
