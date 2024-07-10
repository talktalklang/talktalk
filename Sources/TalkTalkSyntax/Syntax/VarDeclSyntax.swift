public struct VarDeclSyntax: Decl, Syntax {
	public let position: Int
	public let length: Int
	public var variable: IdentifierSyntax
	public var expr: (any Expr)?

	public var description: String {
		if let expr {
			"var \(variable.description) = \(expr.description)"
		} else {
			"var \(variable.description)"
		}
	}
}
