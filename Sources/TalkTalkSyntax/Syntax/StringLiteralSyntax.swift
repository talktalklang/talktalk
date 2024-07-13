//
//  StringLiteralSyntax.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct StringLiteralSyntax: Syntax, Expr {
	public let start: Token
	public let end: Token
	public let lexeme: String

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}

extension StringLiteralSyntax: Consumable {
	static func consuming(_ token: Token) -> StringLiteralSyntax? {
		if token.kind == .string {
			return StringLiteralSyntax(
				start: token,
				end: token,
				lexeme: token.lexeme!
			)
		}

		return nil
	}
}
