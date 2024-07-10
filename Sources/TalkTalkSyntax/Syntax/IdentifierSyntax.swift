public struct IdentifierSyntax: Syntax {
	public let position: Int
	public let length: Int
	public let lexeme: String

	public var description: String {
		lexeme
	}

	public var debugDescription: String {
		"""
		IdentifierSyntax(position: \(position), length: \(length))
			lexeme: \(lexeme)
		"""
	}
}

extension IdentifierSyntax: Consumable {
	static func consuming(_ token: Token) -> IdentifierSyntax? {
		if token.kind == .identifier {
			return IdentifierSyntax(
				position: token.start,
				length: token.length,
				lexeme: token.lexeme!
			)
		}

		return nil
	}
}
