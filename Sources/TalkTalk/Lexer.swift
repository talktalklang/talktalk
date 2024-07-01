//
//  Lexer.swift
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
}

struct Lexer: ~Copyable {
	var source: String
	var start: String.Index
	var current: String.Index
	var line = 1

	init(source: String) {
		self.source = source
		self.start = source.startIndex
		self.current = source.startIndex
	}

	mutating func collect() -> [Token] {
		var result: [Token] = []
		while true {
			let token = next()
			result.append(token)
			if token.kind == .eof {
				break
			}
		}
		return result
	}

	mutating func rewind() {
		current = source.startIndex
		start = source.startIndex
	}

	mutating func dump() -> String {
		var lastLine = 0
		var result = ""

		for token in collect() {
			if token.line != lastLine {
				result += String(format: "%4d ", token.line)
			} else {
				result += "   | "
			}

			result += "\(token.kind) \(source[token.start..<source.index(token.start, offsetBy: token.length)])"
			result += "\n"

			lastLine = token.line
		}

		return result
	}

	mutating func next() -> Token {
		start = current

		if isAtEnd { return make(.eof) }

		let char = advance()
		return switch char {
		case "(": make(.leftParen)
		case ")": make(.rightParen)
		case "{": make(.leftBrace)
		case "}": make(.rightBrace)
		case ",": make(.comma)
		case ".": make(.dot)
		case "-": make(.minus)
		case "+": make(.plus)
		case ";": make(.semicolon)
		case "*": make(.star)
		case "!": make(match("=") ? .bangEqual : .bang)
		case "=": make(match("=") ? .equalEqual : .equal)
		case "<": make(match("=") ? .lessEqual : .less)
		case ">": make(match("=") ? .greaterEqual : .greater)
		default:
			error("Unexpected character.")
		}
	}

	mutating func match(_ char: Character) -> Bool {
		if isAtEnd { return false }

		if source[current] != char {
			return false
		}

		current = source.index(current, offsetBy: 1)
		return true
	}

	mutating func advance() -> Character {
		defer {
			current = source.index(current, offsetBy: 1)
		}

		return source[current]
	}

	func make(_ kind: Token.Kind) -> Token {
		Token(start: start, length: source.distance(from: start, to: current), kind: kind, line: line)
	}

	func error(_ message: String) -> Token {
		make(.error(message))
	}

	var isAtEnd: Bool {
		current == source.endIndex
	}
}
