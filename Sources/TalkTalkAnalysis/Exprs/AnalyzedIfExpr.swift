//
//  AnalyzedIfExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedIfExpr: AnalyzedExpr, IfExpr {
	public var type: ValueType
	let expr: IfExpr

	public var conditionAnalyzed: any AnalyzedExpr
	public var consequenceAnalyzed: AnalyzedBlockExpr
	public var alternativeAnalyzed: AnalyzedBlockExpr
	public let environment: Analyzer.Environment
	public var analyzedChildren: [any AnalyzedExpr] { [conditionAnalyzed, consequenceAnalyzed, alternativeAnalyzed] }

	public var condition: any Expr { expr.condition }
	public var consequence: any BlockExpr { expr.consequence }
	public var alternative: any BlockExpr { expr.alternative }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
