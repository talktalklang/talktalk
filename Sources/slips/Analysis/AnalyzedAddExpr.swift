//
//  AddExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct AnalyzedAddExpr: AnalyzedExpr, AddExpr {
	public let type: ValueType = .int
	let expr: AddExpr

	public var lhs: any Expr { expr.lhs }
	public var rhs: any Expr { expr.rhs }

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
