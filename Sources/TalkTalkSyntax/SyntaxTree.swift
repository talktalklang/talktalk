//
//  SyntaxTree.swift
//  
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct SyntaxTree {
	public var root: [any Syntax]

	public static func parse(source: String) -> SyntaxTree {
		let lexer = Lexer(source: source)
		var parser = Parser(lexer: lexer)

		return SyntaxTree(root: parser.parse())
	}
}
