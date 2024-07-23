public struct Symbol {
	public let token: Token
	public var lexeme: String {
		token.lexeme
	}
}
