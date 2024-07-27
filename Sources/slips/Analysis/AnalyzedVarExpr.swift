//
//  AnalyzedVarExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct AnalyzedVarExpr: AnalyzedExpr, VarExpr {
	public var type: ValueType
	let expr: VarExpr

	public var token: Token { expr.token }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}

	public var name: String {
		token.lexeme
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor {
		visitor.visit(self, scope)
	}
}
