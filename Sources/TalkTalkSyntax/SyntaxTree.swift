//
//  SyntaxTree.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public enum ParserError: Swift.Error {
	case errors([Error])
}

public struct SyntaxTree {
	public var root: [any Syntax]

	public static func parse(filename: String, source: String) throws -> ProgramSyntax {
		let lexer = Lexer(source: source)
		var parser = Parser(lexer: lexer)

		let start = parser.current
		let decls = parser.parse()

		if !parser.errors.isEmpty {
			throw ParserError.errors(parser.errors)
		}

		return ProgramSyntax(
			filename: filename,
			start: start,
			end: parser.current,
			decls: decls
		)
	}
}
