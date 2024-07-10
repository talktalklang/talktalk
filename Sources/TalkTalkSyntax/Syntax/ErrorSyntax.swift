//
//  ErrorSyntax.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
struct ErrorSyntax: Syntax, Expr, Decl {
	enum Expectation {
		case type(any Syntax.Type), token(Token.Kind)
	}

	var token: Token
	var expected: Expectation
	var message: String?

	var position: Int { token.start }
	var length: Int { token.length }

	var description: String {
		"\(message ?? "Error"): \(token), expected: \(expected)"
	}
}
