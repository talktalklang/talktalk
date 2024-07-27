//
//  AnalyzedErrorExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct AnalyzedErrorExpr: AnalyzedExpr, ErrorExpr {
	public var type: ValueType
	public var message: String

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor {
		visitor.visit(self, scope)
	}
}
