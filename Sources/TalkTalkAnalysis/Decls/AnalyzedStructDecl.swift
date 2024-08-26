// Generated by Dev/generate-type.rb 08/13/2024 10:30

import TalkTalkBytecode
import TalkTalkSyntax

public struct AnalyzedStructDecl: StructDecl, AnalyzedDecl {
	public let symbol: Symbol
	public let wrapped: StructDeclSyntax

	public let bodyAnalyzed: AnalyzedDeclBlock
	public let structType: StructType
	public let lexicalScope: LexicalScope

	// AnalyzedDecl conformance
	public var typeID: TypeID
	public var analyzedChildren: [any AnalyzedSyntax] {
		[
			bodyAnalyzed,
		]
	}

	public var environment: Environment

	// Delegate these to the wrapped node
	public var structToken: Token { wrapped.structToken }
	public var name: String { wrapped.name }
	public var nameToken: Token { wrapped.nameToken }
	public var body: DeclBlockSyntax { wrapped.body }
	public var genericParams: (any GenericParams)? { wrapped.genericParams }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }
	public var conformances: [TypeExprSyntax] { wrapped.conformances }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(wrapped, context)
	}
}
