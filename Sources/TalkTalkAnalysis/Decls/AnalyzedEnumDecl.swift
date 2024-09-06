// Generated by Dev/generate-type.rb 09/04/2024 18:29

import TalkTalkSyntax

public struct AnalyzedEnumDecl: EnumDecl, AnalyzedDecl {
  public let wrapped: EnumDeclSyntax

	public var casesAnalyzed: [AnalyzedEnumCaseDecl]
	public var inferenceType: InferenceType
	public var environment: Environment
	public var bodyAnalyzed: AnalyzedDeclBlock
	public var analyzedChildren: [any AnalyzedSyntax] {
		[
			bodyAnalyzed
		]
	}

	// Delegate these to the wrapped node
	public var nameToken: Token { wrapped.nameToken }
	public var body: DeclBlockSyntax { wrapped.body }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, context)
	}
}
