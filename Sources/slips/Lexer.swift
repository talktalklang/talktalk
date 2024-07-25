//
//  Lexer.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct Token {
	public enum Kind {
		// Single char tokens
		case leftParen, rightParen,
		     symbol, plus

		// Multiple char tokens
		case int, float, string, identifier

		// Keywords
		case def, `true`, `false`, `if`, `in`, call

		case eof
		case error
	}

	public let kind: Kind
	public let start: Int
	public let length: Int
	public let lexeme: String
}

public struct Lexer {
	let source: ContiguousArray<Character>
	var start = 0
	var current = 0

	public init(_ source: String) {
		self.source = ContiguousArray<Character>(source)
	}

	public mutating func next() -> Token {
		if isAtEnd {
			return make(.eof)
		}

		skipWhitespace()

		start = current

		let char = advance()
		return switch char {
		case "(": make(.leftParen)
		case ")": make(.rightParen)
		case "+": make(.plus)
		case "'": string()
		case _ where char.isMathSymbol: symbol()
		case _ where char.isNumber: number()
		default:
			if char.isLetter {
				identifier()
			} else {
				error("unexpected character: \(char)")
			}
		}
	}

	public mutating func collect() -> [Token] {
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

	// MARK: Recognizers

	mutating func identifier() -> Token {
		while !isAtEnd, peek().isLetter || peek().isNumber || peek() == "-" || peek() == "_" {
			advance()
		}

		return switch String(source[start ..< current]) {
		case "def": make(.def)
		case "true": make(.true)
		case "false": make(.false)
		case "if": make(.if)
		case "in": make(.in)
		case "call": make(.call)
		default:
			make(.identifier)
		}
	}

	mutating func string() -> Token {
		while advance() != "'", !isAtEnd {}

		return make(.string)
	}

	mutating func symbol() -> Token {
		while peek().isMathSymbol, !isAtEnd {
			advance()
		}

		return make(.symbol)
	}

	mutating func number() -> Token {
		var isFloat = false

		while !isAtEnd, peek().isNumber || (!isFloat && peek() == ".") {
			if peek() == "." {
				isFloat = true
			}

			advance()
		}

		return make(isFloat ? .float : .int)
	}

	// MARK: Helpers

	mutating func skipWhitespace() {
		while !isAtEnd, peek().isWhitespace {
			advance()
		}
	}

	func peek() -> Character {
		source[current]
	}

	@discardableResult mutating func advance() -> Character {
		defer {
			current += 1
		}

		return source[current]
	}

	mutating func make(_ kind: Token.Kind) -> Token {
		Token(
			kind: kind,
			start: start,
			length: current - start,
			lexeme: String(source[start ..< current])
		)
	}

	var isAtEnd: Bool {
		source.count == current
	}

	mutating func error(_ message: String) -> Token {
		print(message)
		return make(.error)
	}
}