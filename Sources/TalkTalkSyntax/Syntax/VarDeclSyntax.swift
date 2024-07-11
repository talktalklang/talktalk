public struct VarDeclSyntax: Decl, Syntax {
	public let position: Int
	public let length: Int
	public var variable: IdentifierSyntax
	public var typeDecl: TypeDeclSyntax?
	public var expr: (any Expr)?

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
