//
//  AnalyzedLetPattern.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/29/24.
//

import TalkTalkCore

public struct AnalyzedLetPattern: AnalyzedSyntax {
	public let wrapped: LetPatternSyntax
	public var inferenceType: InferenceType
	public var analyzedChildren: [any AnalyzedSyntax]
	public var environment: Environment

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
	
	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V : TalkTalkCore.Visitor {
		try visitor.visit(wrapped, context)
	}
}
