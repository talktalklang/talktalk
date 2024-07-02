//
//  Token.swift
//  
//
//  Created by Pat Nakajima on 7/1/24.
//
struct Token: Equatable {
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
				 or, print, `return`, `super`, `self`, `true`, `var`, `while`

		case eof

		case error(String)
	}

	let start: String.Index
	let length: Int
	let kind: Kind
	let line: Int

	init(start: String.Index, length: Int, kind: Kind, line: Int) {
		self.start = start
		self.length = length
		self.kind = kind
		self.line = line
	}

	func lexeme(in source: String) -> Substring {
		source[start..<source.index(start, offsetBy: length)]
	}
}

