//
//  AnalyzedTypeExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/11/24.
//

import TalkTalkBytecode
import TalkTalkSyntax

public struct AnalyzedTypeExpr: TypeExpr, AnalyzedExpr {
	public let wrapped: TypeExprSyntax

	public let symbol: Symbol
	public let typeID: TypeID
	public var analyzedChildren: [any AnalyzedSyntax] { [] }
	public var environment: Environment

	public var identifier: TalkTalkSyntax.Token { wrapped.identifier }
	public var genericParams: (any TalkTalkSyntax.GenericParams)? { wrapped.genericParams }
	public var location: TalkTalkSyntax.SourceLocation { wrapped.location }
	public var children: [any TalkTalkSyntax.Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: TalkTalkSyntax.Visitor {
		try visitor.visit(self, context)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
