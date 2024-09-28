// Generated by Dev/generate-type.rb 08/22/2024 17:44

import TalkTalkCore

public struct AnalyzedDictionaryLiteralExpr: DictionaryLiteralExpr, AnalyzedExpr {
	public var elementsAnalyzed: [AnalyzedDictionaryElementExpr]
	public let wrapped: DictionaryLiteralExprSyntax

	public var inferenceType: InferenceType
	public var environment: Environment
	public var analyzedChildren: [any AnalyzedSyntax] { elementsAnalyzed }

	// Delegate these to the wrapped node
	public var elements: [any DictionaryElementExpr] { wrapped.elements }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, context)
	}
}
