//
//  AnalyzedUnaryExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkSyntax

public struct AnalyzedUnaryExpr: AnalyzedExpr, UnaryExpr {
	public let typeID: TypeID
	public var exprAnalyzed: any AnalyzedExpr
	public var analyzedChildren: [any AnalyzedSyntax] { [exprAnalyzed] }
	public let environment: Environment

	public let wrapped: UnaryExprSyntax

	public var location: SourceLocation { wrapped.location }
	public var op: Token.Kind { wrapped.op }
	public var expr: any Expr { wrapped.expr }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
