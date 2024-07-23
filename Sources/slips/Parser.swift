//
//  Parser.swift
//  
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct Parser {
	var lexer: Lexer

	public init(_ lexer: Lexer) {
		self.lexer = lexer
	}

	public func parse() -> AST {
		AST()
	}
}
