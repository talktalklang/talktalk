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
	public var typeAnalyzed: ValueType

	var stmt: any ImportStmt
	public var token: Token { stmt.token }
	public var module: IdentifierExpr { stmt.module }
	public var location: SourceLocation { stmt.location }
	public var children: [any Syntax] { stmt.children }
	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value
	where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
