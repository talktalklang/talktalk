//
//  AnalyzedDeclBlock.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkSyntax

public struct AnalyzedDeclBlock: DeclBlockExpr, AnalyzedDecl {
	public var type: ValueType
	
	let decl: DeclBlockExpr

	public var declsAnalyzed: [any AnalyzedDecl]

	public var decls: [any TalkTalkSyntax.Decl] { decl.decls }
	public var location: TalkTalkSyntax.SourceLocation { decl.location }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : TalkTalkSyntax.Visitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
