//
//  AnalyzedExprStmt.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/12/24.
//

import TalkTalkSyntax

public struct AnalyzedExprStmt: ExprStmt, AnalyzedSyntax, AnalyzedDecl, AnalyzedExpr {
	var wrapped: any ExprStmt
	public var exprAnalyzed: any AnalyzedExpr
	public var typeID: TypeID { exprAnalyzed.typeID }

	public var analyzedChildren: [any AnalyzedSyntax] { [exprAnalyzed] }
	public var environment: Environment

	public var expr: any Expr { wrapped.expr }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: TalkTalkSyntax.Visitor {
		try visitor.visit(self, context)
	}
}
