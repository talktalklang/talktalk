//
//  LiteralExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public enum LiteralValue {
	case int(Int), bool(Bool)
}

public protocol LiteralExpr: Expr {
	var value: LiteralValue { get }
}

public struct LiteralExprSyntax: LiteralExpr {
	public let value: LiteralValue

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}
}
