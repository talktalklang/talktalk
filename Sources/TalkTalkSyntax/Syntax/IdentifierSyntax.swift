public struct IdentifierSyntax: Syntax {
	public let position: Int
	public let length: Int
	public let lexeme: String

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
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
