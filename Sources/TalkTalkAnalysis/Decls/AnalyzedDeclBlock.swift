//
//  AnalyzedDeclBlock.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkSyntax

public struct AnalyzedDeclBlock: DeclBlock, AnalyzedDecl {
	public let typeID: TypeID

	let decl: DeclBlock

	public var declsAnalyzed: [any AnalyzedDecl]
	public var analyzedChildren: [any AnalyzedSyntax] { declsAnalyzed }
	public let environment: Environment

	public var decls: [any TalkTalkSyntax.Syntax] { decl.decls }
	public var location: TalkTalkSyntax.SourceLocation { decl.location }
	public var children: [any Syntax] { decl.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : TalkTalkSyntax.Visitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
