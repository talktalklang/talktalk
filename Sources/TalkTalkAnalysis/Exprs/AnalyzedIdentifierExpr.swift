//
//  AnalyzedIdentifierExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import TalkTalkSyntax

public struct AnalyzedIdentifierExpr: AnalyzedExpr, IdentifierExpr {
	public var type: ValueType
	
	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	var expr: IdentifierExpr
	public var analyzedChildren: [any AnalyzedExpr] { [] }
	public var name: String { expr.name }
	public var location: SourceLocation { expr.location }
	public let environment: Analyzer.Environment
	public var children: [any Syntax] { expr.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : TalkTalkSyntax.Visitor {
		try visitor.visit(self, scope)
	}
	

}
