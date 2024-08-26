//
//  AnalyzedStructExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkSyntax

public struct AnalyzedStructExpr: AnalyzedExpr, StructExpr {
	public let typeID: TypeID
	public let wrapped: StructExprSyntax

	public let bodyAnalyzed: AnalyzedDeclBlock
	public let structType: StructType
	public let lexicalScope: LexicalScope
	public var analyzedChildren: [any AnalyzedSyntax] { [bodyAnalyzed] }
	public let environment: Environment

	public var structToken: Token { wrapped.structToken }
	public var name: String? { wrapped.name }
	public var genericParams: (any GenericParams)? { wrapped.genericParams }
	public var body: DeclBlock { wrapped.body }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
