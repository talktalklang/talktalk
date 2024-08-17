//
//  AnalyzedBlockStmt.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

import TalkTalkSyntax

public struct AnalyzedBlockStmt: AnalyzedExpr, BlockStmt {
	let stmt: any BlockStmt
	public let typeID: TypeID

	public var stmtsAnalyzed: [any AnalyzedSyntax]
	public var analyzedChildren: [any AnalyzedSyntax] { stmtsAnalyzed }
	public let environment: Environment

	public var stmts: [any Stmt] { stmt.stmts }
	public var location: SourceLocation { stmt.location }
	public var children: [any Syntax] { stmt.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
