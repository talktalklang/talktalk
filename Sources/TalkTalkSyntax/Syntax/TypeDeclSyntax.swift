public struct TypeDeclSyntax: Syntax {
	public let start: Token
	public let end: Token
	public let name: IdentifierSyntax
	public func accept<Visitor>(_ visitor: inout Visitor) -> Visitor.Value where Visitor: ASTVisitor {
		visitor.visit(self)
	}
}
