//
//  AnalyzedGenericParams.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/11/24.
//

import TalkTalkSyntax

public struct AnalyzedGenericParam {
	let wrapped: any GenericParam
	public var name: String { wrapped.name }
}

public struct AnalyzedGenericParams: GenericParams, AnalyzedSyntax {
	let wrapped: any GenericParams
	public var type: ValueType
	public var paramsAnalyzed: [AnalyzedGenericParam]
	public var analyzedChildren: [any AnalyzedSyntax] { [] }

	public var params: [any TalkTalkSyntax.GenericParam] { wrapped.params }
	public var location: TalkTalkSyntax.SourceLocation { wrapped.location }
	public var children: [any TalkTalkSyntax.Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V : TalkTalkSyntax.Visitor {
		try visitor.visit(self, context)
	}
	

}
