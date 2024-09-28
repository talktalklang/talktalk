// Generated by Dev/generate-type.rb 08/22/2024 17:46

import TalkTalkCore

public struct AnalyzedDictionaryElementExpr: DictionaryElementExpr, AnalyzedExpr {
	public var keyAnalyzed: any AnalyzedExpr
	public var valueAnalyzed: any AnalyzedExpr

	public let wrapped: DictionaryElementExprSyntax

	public var inferenceType: InferenceType
	public var environment: Environment
	public var analyzedChildren: [any AnalyzedSyntax] { [keyAnalyzed, valueAnalyzed] }

	// Delegate these to the wrapped node
	public var key: any Expr { wrapped.key }
	public var value: any Expr { wrapped.value }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, context)
	}
}
