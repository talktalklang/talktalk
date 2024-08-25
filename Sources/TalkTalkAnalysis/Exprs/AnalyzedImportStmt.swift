//
//  AnalyzedImportStmt.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkSyntax

public struct AnalyzedImportStmt: ImportStmt, AnalyzedStmt {
	public var analyzedChildren: [any AnalyzedSyntax] { [] }
	public var environment: Environment
	public let typeID: TypeID

	public let wrapped: ImportStmtSyntax
	public var token: Token { wrapped.token }
	public var module: IdentifierExpr { wrapped.module }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }
	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value
		where V: AnalyzedVisitor
	{
		try visitor.visit(self, scope)
	}
}
