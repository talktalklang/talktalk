// Generated by Dev/generate-type.rb 09/29/2024 09:37

import TalkTalkCore

public struct AnalyzedGroupedExpr: GroupedExpr, AnalyzedExpr {
  public let wrapped: GroupedExprSyntax
	public var exprAnalyzed: any AnalyzedExpr

	public var inferenceType: InferenceType
	public var environment: Environment
	public var analyzedChildren: [any AnalyzedSyntax] { [exprAnalyzed] }

	// Delegate these to the wrapped node
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }
	public var expr: any Expr { wrapped.expr }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, context)
	}
}