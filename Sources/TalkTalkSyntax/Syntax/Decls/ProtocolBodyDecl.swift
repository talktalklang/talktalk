// Generated by Dev/generate-type.rb 08/26/2024 12:57

public protocol ProtocolBodyDecl: Decl {
	// Insert ProtocolBodyDecl specific fields here
}

public struct ProtocolBodyDeclSyntax: ProtocolBodyDecl {
	public var decls: [any Decl]

  // A unique identifier
  public var id: SyntaxID

	// Where does this syntax live
	public var location: SourceLocation

	// Useful for just traversing the whole tree
	public var children: [any Syntax] { decls }

	// Let this node be visited by visitors
	public func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(self, context)
	}
}
