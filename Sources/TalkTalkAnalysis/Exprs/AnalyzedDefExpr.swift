//
//  AnalyzedDefExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkCore

public struct AnalyzedDefExpr: AnalyzedExpr, DefExpr {
	public var value: any Expr { wrapped.value }

	public let inferenceType: InferenceType
	public let wrapped: DefExprSyntax

	public var receiver: any Expr { wrapped.receiver }
	public var receiverAnalyzed: any AnalyzedExpr
	public var analysisErrors: [AnalysisError]

	public var valueAnalyzed: any AnalyzedExpr
	public var analyzedChildren: [any AnalyzedSyntax] { [receiverAnalyzed, valueAnalyzed] }
	public let environment: Environment
	public var op: Token { wrapped.op }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
