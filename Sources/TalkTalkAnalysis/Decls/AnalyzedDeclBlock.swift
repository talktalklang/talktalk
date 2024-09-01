//
//  AnalyzedDeclBlock.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkSyntax

public struct AnalyzedDeclBlock: DeclBlock, AnalyzedDecl {
	public let inferenceType: InferenceType

	public let wrapped: DeclBlockSyntax

	public var declsAnalyzed: [any AnalyzedDecl]
	public var analyzedChildren: [any AnalyzedSyntax] { declsAnalyzed }
	public let environment: Environment

	public var decls: [any TalkTalkSyntax.Syntax] { wrapped.decls }
	public var location: TalkTalkSyntax.SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: TalkTalkSyntax.Visitor {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
