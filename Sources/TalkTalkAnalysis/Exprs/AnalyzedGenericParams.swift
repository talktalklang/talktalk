//
//  AnalyzedGenericParams.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/11/24.
//

import TalkTalkCore

public struct AnalyzedGenericParam {
	let wrapped: any GenericParam
	public var type: any TypeExpr { wrapped.type }
}

public struct AnalyzedGenericParams: GenericParams, AnalyzedSyntax {
	public let wrapped: GenericParamsSyntax
	public var environment: Environment
	public let inferenceType: InferenceType
	public var paramsAnalyzed: [AnalyzedGenericParam]
	public var analyzedChildren: [any AnalyzedSyntax] { [] }

	public var params: [any GenericParam] { wrapped.params }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(wrapped, context)
	}
}
