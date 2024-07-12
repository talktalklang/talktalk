//
//  ErrorSyntax.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct ErrorSyntax: Syntax, Expr, Decl {
	enum Expectation {
		case type(any Syntax.Type), token(Token.Kind), none
	}

	var token: Token
	var expected: Expectation
	public var message: String

	public var start: Token { token }
	public var end: Token { token }

	public var description: String {
		"\(message): \(token), expected: \(expected)"
	}

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
