//
//  ErrorSyntax.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
struct ErrorSyntax: Syntax, Expr {
	var token: Token
	var expected: Token.Kind? = nil

	var position: Int { token.start }
	var length: Int { token.length }
}