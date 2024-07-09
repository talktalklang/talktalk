//
//  Token.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//
struct Token: Equatable, Sendable {
	typealias Kinds = Set<Token.Kind>

	static func synthetic(_ kind: Token.Kind, length: Int) -> Token {
		Token(start: -length, length: length, kind: kind, line: 0, lexeme: "\(kind)")
	}

	enum Kind: Equatable, Hashable {
		case bof // Placeholder for previous when we first start

		// Single character tokens
		case leftParen, rightParen,
		     leftBrace, rightBrace,
		     leftBracket, rightBracket,
		     comma, dot, minus, plus, semicolon, slash, star, colon

		// One or two character tokens
		case bang, bangEqual, equal, equalEqual,
		     greater, greaterEqual, less, lessEqual,
		     and, andAnd, pipe, pipePipe

		// Literals
		case identifier, string, number

		// Keywords
		case `class`, `else`, `false`, `func`, `init`, `for`, `if`, `nil`,
		     or, `return`, `super`, `self`, `true`, `var`, `while`

		case newline

		case eof
		case print

		case error(String)
	}

	let start: Int
	let length: Int
	let kind: Kind
	let line: Int
	let lexeme: String?

	init(start: Int, length: Int, kind: Kind, line: Int, lexeme: String?) {
		self.start = start
		self.length = length
		self.kind = kind
		self.line = line
		self.lexeme = lexeme
	}

	var description: String {
		return "\(kind) `\(lexeme ?? "")` position: \(start) line: \(line)"
	}
}

extension Token.Kinds {
	static let statementTerminators: Token.Kinds = [
		.semicolon,
		.newline,
		.eof,
	]
}
