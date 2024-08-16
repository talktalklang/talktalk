//
//  AnalyzedIfExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedIfExpr: AnalyzedExpr, IfExpr {
	public let typeID: TypeID
	let expr: IfExpr

	public var conditionAnalyzed: any AnalyzedExpr
	public var consequenceAnalyzed: AnalyzedBlockStmt
	public var alternativeAnalyzed: AnalyzedBlockStmt
	public let environment: Environment
	public var analyzedChildren: [any AnalyzedSyntax] { [conditionAnalyzed, consequenceAnalyzed, alternativeAnalyzed] }

	public var ifToken: Token { expr.ifToken }
	public var elseToken: Token? { expr.elseToken }
	public var condition: any Expr { expr.condition }
	public var consequence: any BlockStmt { expr.consequence }
	public var alternative: any BlockStmt { expr.alternative }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
