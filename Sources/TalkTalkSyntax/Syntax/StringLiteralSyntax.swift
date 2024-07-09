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
