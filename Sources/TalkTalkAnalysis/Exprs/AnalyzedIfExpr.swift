//
//  AnalyzedIfExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedIfExpr: AnalyzedExpr, IfExpr {
	public let typeID: TypeID
	public let wrapped: IfExprSyntax

	public var conditionAnalyzed: any AnalyzedExpr
	public var consequenceAnalyzed: AnalyzedBlockStmt
	public var alternativeAnalyzed: AnalyzedBlockStmt
	public let environment: Environment
	public let analysisErrors: [AnalysisError]
	public var analyzedChildren: [any AnalyzedSyntax] { [conditionAnalyzed, consequenceAnalyzed, alternativeAnalyzed] }

	public var ifToken: Token { wrapped.ifToken }
	public var elseToken: Token? { wrapped.elseToken }
	public var condition: any Expr { wrapped.condition }
	public var consequence: any BlockStmt { wrapped.consequence }
	public var alternative: any BlockStmt { wrapped.alternative }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
