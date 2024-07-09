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
}
