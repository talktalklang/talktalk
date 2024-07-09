//
//  StringLiteralSyntax.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct StringLiteralSyntax: Syntax, Expr {
	public let position: Int
	public let length: Int
	public let lexeme: String
}

extension StringLiteralSyntax: Consumable {
	static func consuming(_ token: Token) -> StringLiteralSyntax? {
		if token.kind == .string {
			return StringLiteralSyntax(
				position: token.start,
				length: token.length,
				lexeme: token.lexeme!
			)
		}

		return nil
	}
}
