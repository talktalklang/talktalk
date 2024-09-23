//
//  AnalyzedMemberExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax
import TalkTalkBytecode
import TypeChecker

public struct AnalyzedMemberExpr: AnalyzedExpr, MemberExpr {
	public let inferenceType: InferenceType
	public let wrapped: MemberExprSyntax
	public var analyzedChildren: [any AnalyzedSyntax] { [receiverAnalyzed] }
	public let environment: Environment

	public let receiverAnalyzed: any AnalyzedExpr
	public let memberSymbol: Symbol
	public let analysisErrors: [AnalysisError]
	public let analysisDefinition: Definition?

	public var receiver: (any Expr)? { wrapped.receiver }
	public var property: String { wrapped.property }
	public var propertyToken: Token { wrapped.propertyToken }
	public var isMutable: Bool

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func definition() -> Definition? {
		analysisDefinition
	}
}
