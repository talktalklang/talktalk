//
//  AnalyzedBinaryExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedBinaryExpr: AnalyzedExpr, BinaryExpr {
	public let inferenceType: InferenceType
	public let wrapped: BinaryExprSyntax

	public let lhsAnalyzed: any AnalyzedExpr
	public let rhsAnalyzed: any AnalyzedExpr
	public var analyzedChildren: [any AnalyzedSyntax] { [lhsAnalyzed, rhsAnalyzed] }
	public let environment: Environment

	public var lhs: any Expr { wrapped.lhs }
	public var rhs: any Expr { wrapped.rhs }
	public var op: BinaryOperator { wrapped.op }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
