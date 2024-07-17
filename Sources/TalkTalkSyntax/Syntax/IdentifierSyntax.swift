public struct IdentifierSyntax: Syntax {
	public let start: Token
	public let end: Token
	public let lexeme: String

	public func accept<Visitor: ASTVisitor>(
		_ visitor: Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}

extension IdentifierSyntax: Consumable {
	static func consuming(_ token: Token) -> IdentifierSyntax? {
		if token.kind == .identifier {
			return IdentifierSyntax(
				start: token,
				end: token,
				lexeme: token.lexeme!
			)
		}

		return nil
	}
}
