//
//  AnalyzedLetDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkBytecode
import TalkTalkSyntax

public struct AnalyzedLetDecl: AnalyzedExpr, AnalyzedDecl, LetDecl, AnalyzedVarLetDecl {
	public let symbol: Symbol?
	public let typeID: TypeID
	let expr: LetDecl
	public var analysisErrors: [AnalysisError]
	public var valueAnalyzed: (any AnalyzedExpr)?
	public var analyzedChildren: [any AnalyzedSyntax] {
		if let valueAnalyzed { [valueAnalyzed] } else { [] }
	}

	public let environment: Environment

	public var name: String { expr.name }
	public var nameToken: Token { expr.nameToken }
	public var token: Token { expr.token }
	public var typeExpr: (any TypeExpr)? { expr.typeExpr }
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
