// Generated by Dev/generate-type.rb 09/04/2024 18:29

public protocol EnumDecl: Decl {
	// Insert EnumDecl specific fields here
	var nameToken: Token { get }
	var conformances: [TypeExprSyntax] { get }
}

public struct EnumDeclSyntax: EnumDecl {
	public var enumToken: Token
	public var nameToken: Token
	public var conformances: [TypeExprSyntax]
	public var body: DeclBlockSyntax
	public var typeParams: [TypeExprSyntax]

	// A unique identifier
	public var id: SyntaxID

	// Where does this syntax live
	public var location: SourceLocation

	// Useful for just traversing the whole tree
	public var children: [any Syntax] {
		[
			body,
		] + typeParams
	}

	// Let this node be visited by visitors
	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(self, context)
	}
}
