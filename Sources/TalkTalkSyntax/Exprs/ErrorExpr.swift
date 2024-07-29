//
//  ErrorExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol ErrorExpr: Expr {
	var message: String { get }
}

public struct ErrorExprSyntax: ErrorExpr {
	public var message: String

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}
}
