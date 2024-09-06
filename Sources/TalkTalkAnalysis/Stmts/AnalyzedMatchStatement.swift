// Generated by Dev/generate-type.rb 09/04/2024 21:04

import TalkTalkSyntax

public struct AnalyzedMatchStatement: MatchStatement, AnalyzedStmt {
  public let wrapped: MatchStatementSyntax
	public var targetAnalyzed: any AnalyzedExpr
	public var casesAnalyzed: [AnalyzedCaseStmt]

	public var inferenceType: InferenceType
	public var environment: Environment
	public var analyzedChildren: [any AnalyzedSyntax] { [targetAnalyzed] + casesAnalyzed }

	// Delegate these to the wrapped node
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, context)
	}
}