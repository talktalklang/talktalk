//
//  AnalyzedCallExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedArgument: AnalyzedSyntax {
	public var inferenceType: InferenceType { expr.inferenceType }
	public var environment: Environment
	public var analyzedChildren: [any AnalyzedSyntax] { expr.analyzedChildren }
	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try expr.accept(visitor, scope)
	}

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: Visitor {
		try expr.accept(visitor, context)
	}

	public let label: Token?
	public let wrapped: Argument
	public let expr: any AnalyzedExpr
}

public struct AnalyzedCallExpr: AnalyzedExpr, CallExpr {
	public let inferenceType: InferenceType
	public let wrapped: CallExprSyntax

	public var calleeAnalyzed: any AnalyzedExpr
	public var argsAnalyzed: [AnalyzedArgument]
	public var analyzedChildren: [any AnalyzedSyntax] {
		[calleeAnalyzed] + argsAnalyzed.map(\.expr)
	}

	public var analysisErrors: [AnalysisError]
	public let environment: Environment

	public var callee: any Expr { wrapped.callee }
	public var args: [Argument] { wrapped.args }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
