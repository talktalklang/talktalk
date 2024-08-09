//
//  AnalyzedInitDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import TalkTalkSyntax

public struct AnalyzedInitDecl: AnalyzedDecl, InitDecl {
	let wrapped: InitDecl

	public var type: ValueType
	public var environment: Environment
	public var parametersAnalyzed: AnalyzedParamsExpr
	public var bodyAnalyzed: AnalyzedBlockExpr
	public var analyzedChildren: [any AnalyzedSyntax] {
		[parametersAnalyzed, bodyAnalyzed]
	}

	public var initToken: Token { wrapped.initToken }
	public var parameters: any ParamsExpr { wrapped.parameters }
	public var body: any BlockExpr { wrapped.body }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V : TalkTalkSyntax.Visitor {
		try visitor.visit(self, context)
	}
}
