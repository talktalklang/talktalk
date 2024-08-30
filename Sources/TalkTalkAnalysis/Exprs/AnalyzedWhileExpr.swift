//
//  AnalyzedWhileExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

import TalkTalkSyntax

public struct AnalyzedWhileStmt: WhileStmt, AnalyzedStmt {
	public let typeID: TypeID
	public let wrapped: WhileStmtSyntax

	public var conditionAnalyzed: any AnalyzedExpr
	public var bodyAnalyzed: AnalyzedBlockStmt
	public var analyzedChildren: [any AnalyzedSyntax] { [conditionAnalyzed, bodyAnalyzed] }
	public let environment: Environment

	public var whileToken: Token { wrapped.whileToken }
	public var condition: any Expr { wrapped.condition }
	public var body: any BlockStmt { wrapped.body }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(wrapped, scope)
	}
}
