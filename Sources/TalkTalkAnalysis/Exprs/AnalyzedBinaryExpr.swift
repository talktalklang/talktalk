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
	public var location: SourceLocation { expr.location }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
