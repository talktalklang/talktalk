public struct TypeDeclSyntax: Syntax {
	public let start: Token
	public let end: Token
	public let name: IdentifierSyntax
	public let optional: Bool

	public func accept<Visitor: ASTVisitor>(
		_ visitor: Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
