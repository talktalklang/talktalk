//
//  AnalyzedAddExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedBinaryExpr: AnalyzedExpr, BinaryExpr {
	public var type: ValueType
	let expr: any BinaryExpr

	public let lhsAnalyzed: any AnalyzedExpr
	public let rhsAnalyzed: any AnalyzedExpr

	public var lhs: any Expr { expr.lhs }
	public var rhs: any Expr { expr.rhs }
	public var op: BinaryOperator { expr.op }

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor {
		visitor.visit(self, scope)
	}
}
