public struct VarExpr: Expr {
	public let token: Token

	public var name: String {
		token.lexeme
	}
}
