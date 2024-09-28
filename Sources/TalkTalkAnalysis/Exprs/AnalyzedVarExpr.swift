//
//  AnalyzedVarExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkBytecode
import TalkTalkCore

public struct AnalyzedVarExpr: AnalyzedExpr, AnalyzedDecl, VarExpr {
	public let inferenceType: InferenceType
	public let wrapped: VarExprSyntax
	public let symbol: Symbol?
	public var analyzedChildren: [any AnalyzedSyntax] { [] }
	public let environment: Environment
	public var analysisErrors: [AnalysisError]
	public var isMutable: Bool

	public var token: Token { wrapped.token }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, scope)
	}

	public var name: String {
		token.lexeme
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func definition() -> Definition? {
		guard let binding = environment.lookup(name) else {
			return nil
		}

		return binding.definition
	}
}
