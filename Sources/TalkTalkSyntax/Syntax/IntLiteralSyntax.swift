//
//  IntLiteral.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct IntLiteralSyntax: Syntax, Expr {
	public var position: Int
	public var length: Int
	public var lexeme: String

	public var description: String {
		lexeme
	}

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value{
		visitor.visit(self)
	}

}

extension IntLiteralSyntax: Consumable {
	static func consuming(_ token: Token) -> IntLiteralSyntax? {
		if token.kind == .number {
			return IntLiteralSyntax(
				position: token.start,
				length: token.length,
				lexeme: token.lexeme!
			)
		}

		return nil
	}
}
