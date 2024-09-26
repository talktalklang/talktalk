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
	public let inferenceType: InferenceType
	public let wrapped: LetDeclSyntax
	public var analysisErrors: [AnalysisError]
	public var valueAnalyzed: (any AnalyzedExpr)?
	public var analyzedChildren: [any AnalyzedSyntax] {
		if let valueAnalyzed { [valueAnalyzed] } else { [] }
	}

	public let environment: Environment

	public var name: String { wrapped.name }
	public var nameToken: Token { wrapped.nameToken }
	public var isStatic: Bool { wrapped.isStatic }
	public var token: Token { wrapped.token }
	public var typeExpr: TypeExprSyntax? { wrapped.typeExpr }
	public var value: (any Expr)? { wrapped.value }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }
	public var modifiers: [Token] { wrapped.modifiers }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
