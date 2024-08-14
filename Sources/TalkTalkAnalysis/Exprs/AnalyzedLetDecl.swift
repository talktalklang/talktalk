//
//  AnalyzedLetDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkSyntax

public struct AnalyzedLetDecl: AnalyzedExpr, AnalyzedDecl, VarDecl {
	public let typeID: TypeID
	let expr: LetDecl
	public var analysisErrors: [AnalysisError]
	public var valueAnalyzed: (any AnalyzedExpr)?
	public var analyzedChildren: [any AnalyzedSyntax] {
		if let valueAnalyzed { [valueAnalyzed] } else { [] }
	}
	public let environment: Environment

	public var name: String { expr.name }
	public var token: Token { expr.token }
	public var typeDecl: String? { expr.typeDecl }
	public var typeDeclToken: Token? { expr.typeDeclToken }
	public var value: (any Expr)? { expr.value }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
