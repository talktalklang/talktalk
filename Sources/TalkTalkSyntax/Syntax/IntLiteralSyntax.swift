//
//  IntLiteral.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct IntLiteralSyntax: Syntax, Expr {
	public let start: Token
	public let end: Token
	public var lexeme: String

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}

extension IntLiteralSyntax: Consumable {
	static func consuming(_ token: Token) -> IntLiteralSyntax? {
		if token.kind == .number {
			return IntLiteralSyntax(
				start: token,
				end: token,
				lexeme: token.lexeme!
			)
		}

		return nil
	}
}
