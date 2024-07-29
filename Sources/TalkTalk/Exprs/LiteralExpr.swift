//
//  LiteralExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol LiteralExpr: Expr {
	var value: Value { get }
}

public struct LiteralExprSyntax: LiteralExpr {
	public let value: Value

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}
}
