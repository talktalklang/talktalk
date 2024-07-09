//
//  Token.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//
struct Token: Equatable, Sendable {
	typealias Kinds = Set<Token.Kind>

	static func synthetic(_ kind: Token.Kind, length: Int) -> Token {
		Token(start: -length, length: length, kind: kind, line: 0)
	}

	enum Kind: Equatable, Hashable {
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

	init(start: Int, length: Int, kind: Kind, line: Int) {
		self.start = start
		self.length = length
		self.kind = kind
		self.line = line
	}

	func same(lexeme other: Token, in source: ContiguousArray<Character>) -> Bool {
		if kind == .self && other.kind == .self {
			return true
		}

		if kind == .super && other.kind == .super {
			return true
		}

		return length == other.length && lexeme(in: source) == other.lexeme(in: source)
	}

	func description(in source: borrowing ContiguousArray<Character>) -> String {
		return "\(kind) `\(String(lexeme(in: source)))` position: \(start) line: \(line)"
	}

	func lexeme(in lexer: borrowing Lexer) -> String {
		String(lexeme(in: lexer.source))
	}

//	@available(*, deprecated, message: "this isn't great")
	func lexeme(in source: borrowing ContiguousArray<Character>) -> String {
		if kind == .self {
			return "self"
		}

		if kind == .super {
			return "super"
		}

		return String(
			source[start ..< start + length]
		)
	}
}

extension Token.Kinds {
	static let statementTerminators: Token.Kinds = [
		.semicolon,
		.newline,
		.eof,
	]
}
