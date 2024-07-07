//
//  Token.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//
struct Token: Equatable, Sendable {
	enum Kind: Equatable {
		// Single character tokens
		case leftParen, rightParen, leftBrace, rightBrace,
		     comma, dot, minus, plus, semicolon, slash, star

		// One or two character tokens
		case bang, bangEqual, equal, equalEqual,
		     greater, greaterEqual, less, lessEqual,
		     and, andAnd, pipe, pipePipe

		// Literals
		case identifier, string, number

		// Keywords
		case `class`, `else`, `false`, `func`, initializer, `for`, `if`, `nil`,
		     or, `return`, `super`, `self`, `true`, `var`, `while`

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
		length == other.length && lexeme(in: source) == other.lexeme(in: source)
	}

	func description(in source: borrowing ContiguousArray<Character>) -> String {
		"\(kind) \(lexeme(in: source))"
	}

//	@available(*, deprecated, message: "this isn't great")
	func lexeme(in source: ContiguousArray<Character>) -> ContiguousArray<Character> {
		ContiguousArray(
			source[start ..< start + length]
		)
	}
}
