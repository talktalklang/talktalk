//
//  VarExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct VarExpr: Expr {
	public let token: Token

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}

	public var name: String {
		token.lexeme
	}
}
