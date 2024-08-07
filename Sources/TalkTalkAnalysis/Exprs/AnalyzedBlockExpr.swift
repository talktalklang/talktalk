//
//  AnalyzedBlockExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

import TalkTalkSyntax

public struct AnalyzedBlockExpr: AnalyzedExpr, BlockExpr {
	public var type: ValueType
	let expr: any BlockExpr

	public var exprsAnalyzed: [any AnalyzedExpr]
	public var analyzedChildren: [any AnalyzedSyntax] { exprsAnalyzed }
	public let environment: Environment

	public var exprs: [any Syntax] { expr.exprs }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
}
