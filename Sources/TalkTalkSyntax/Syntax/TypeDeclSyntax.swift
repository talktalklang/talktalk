public struct TypeDeclSyntax: Syntax {
	public let position: Int
	public let length: Int
	public let name: IdentifierSyntax
	public func accept<Visitor>(_ visitor: inout Visitor) -> Visitor.Value where Visitor : ASTVisitor {
		visitor.visit(self)
	}
}
