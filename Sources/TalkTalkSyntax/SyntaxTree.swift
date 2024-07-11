//
//  SyntaxTree.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct SyntaxTree {
	enum Errors: Swift.Error {
		case errors([Error])
	}

	public var root: [any Syntax]

	public static func parse(source: String) -> ProgramSyntax {
		let lexer = Lexer(source: source)
		var parser = Parser(lexer: lexer)
		let decls = parser.parse()

		return ProgramSyntax(
			position: 0,
			length: parser.current.start,
			decls: decls
		)
	}
}
