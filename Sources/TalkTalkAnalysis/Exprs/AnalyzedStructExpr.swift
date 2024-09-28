//
//  AnalyzedStructExpr.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkCore
import TypeChecker

public struct AnalyzedStructExpr: AnalyzedExpr, StructExpr {
	public let inferenceType: InferenceType
	public let wrapped: StructExprSyntax

	public let bodyAnalyzed: AnalyzedDeclBlock
	public let structType: StructType
	public var analyzedChildren: [any AnalyzedSyntax] { [bodyAnalyzed] }
	public let environment: Environment

	public var structToken: Token { wrapped.structToken }
	public var name: String? { wrapped.name }
	public var typeParameters: [TypeExprSyntax] { wrapped.typeParameters }
	public var body: DeclBlock { wrapped.body }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
