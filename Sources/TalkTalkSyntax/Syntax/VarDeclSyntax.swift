public struct VarDeclSyntax: Decl, Syntax {
	public let start: Token
	public let end: Token
	public var variable: IdentifierSyntax
	public var typeDecl: TypeDeclSyntax?
	public var expr: (any Expr)?

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
