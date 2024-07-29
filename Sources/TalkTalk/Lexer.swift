//
//  Lexer.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct Token: CustomDebugStringConvertible {
	public enum Kind {
		// Single char tokens
		case leftParen, rightParen,
				 leftBrace, rightBrace,
		     symbol, plus, equals, comma, bang

		// Multiple char tokens
		case int, float, identifier, equalEqual, bangEqual

		// Keywords
		case `func`, `true`, `false`, `if`, `in`, call, `else`, `while`

		case newline
		case eof
		case error
	}

	public let kind: Kind
	public let start: Int
	public let length: Int
	public let lexeme: String

	public var debugDescription: String {
		".\(kind)"
	}
}

public struct TalkTalkLexer {
	let source: ContiguousArray<Character>
	var start = 0
	var current = 0

	public init(_ source: String) {
		self.source = ContiguousArray<Character>(source)
	}

	public mutating func rewind(count _: Int) {}

	public mutating func next() -> Token {
		skipWhitespace()

		if isAtEnd {
			return make(.eof)
		}

		start = current

		let char = advance()
		return switch char {
		case "(": make(.leftParen)
		case ")": make(.rightParen)
		case "{": make(.leftBrace)
		case "}": make(.rightBrace)
		case "=": make(match("=") ? .equalEqual : .equals)
		case "!": make(match("=") ? .bangEqual : .bang)
		case "+": make(.plus)
		case ",": make(.comma)
		case _ where char.isNewline: newline()
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

	mutating func newline() -> Token {
		while !isAtEnd, peek().isNewline {
			advance()
		}
		return make(.newline)
	}

	mutating func identifier() -> Token {
		while !isAtEnd, peek().isLetter || peek().isNumber || peek() == "-" || peek() == "_" {
			advance()
		}

		return switch String(source[start ..< current]) {
		case "func": make(.func)
		case "true": make(.true)
		case "false": make(.false)
		case "if": make(.if)
		case "else": make(.else)
		case "in": make(.in)
		case "call": make(.call)
		case "while": make(.while)
		default:
			make(.identifier)
		}
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
		while !isAtEnd, peek().isWhitespace, !peek().isNewline {
			advance()
		}
	}

	mutating func match(_ char: Character) -> Bool {
		if peek() == char {
			advance()
			return true
		}

		return false
	}

	func peek(_ offset: Int = 0) -> Character {
		source[current + offset]
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
			lexeme: kind == .eof ? "EOF" : String(source[start ..< current])
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
