public struct TypeDeclSyntax: Syntax {
	public let start: Token
	public let end: Token
	public let name: IdentifierSyntax
	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: inout Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: &context)
	}
}
