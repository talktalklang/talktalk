//
//  AnalyzedWhileExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

import TalkTalkSyntax

public struct AnalyzedWhileExpr: WhileExpr, AnalyzedExpr {
	public let typeID: TypeID
	let expr: WhileExpr

	public var conditionAnalyzed: any AnalyzedExpr
	public var bodyAnalyzed: AnalyzedBlockExpr
	public var analyzedChildren: [any AnalyzedSyntax] { [conditionAnalyzed, bodyAnalyzed] }
	public let environment: Environment

	public var whileToken: Token { expr.whileToken }
	public var condition: any Expr { expr.condition }
	public var body: any BlockExpr { expr.body }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
}
