//
//  AnalyzedStructExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkSyntax

public struct AnalyzedStructExpr: AnalyzedExpr, StructExpr {
	public var type: ValueType
	let expr: StructExpr

	public let bodyAnalyzed: AnalyzedDeclBlock
	public let structType: StructType
	public let lexicalScope: LexicalScope
	public var analyzedChildren: [any AnalyzedExpr] { [bodyAnalyzed] }
	public let environment: Analyzer.Environment

	public var name: String? { expr.name }
	public var body: DeclBlockExpr { expr.body }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
