// Generated by Dev/generate-type.rb 10/02/2024 12:07

import TalkTalkCore

public struct AnalyzedMethodDecl: MethodDecl, AnalyzedDecl {
  public let wrapped: MethodDeclSyntax
	public var funcTokenAnalyzed: Token
	public var modifiersAnalyzed: [Token]
	public var nameAnalyzed: Token
	public var paramsAnalyzed: ParamsExprSyntax
	public var returnsAnalyzed: TypeExprSyntax
	public var bodyAnalyzed: BlockStmtSyntax
	public var isStaticAnalyzed: Bool

	public var inferenceType: InferenceType
	public var environment: Environment
	public var analyzedChildren: [any AnalyzedSyntax] { [] }

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
