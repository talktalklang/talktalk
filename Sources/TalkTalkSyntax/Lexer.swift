//
//  Lexer.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct Token: CustomDebugStringConvertible, Sendable, Equatable {
	public enum Kind: Sendable, Equatable {
		// Single char tokens
		case leftParen, rightParen,
				 leftBrace, rightBrace,
		     symbol, plus, equals, comma, bang,
				 colon, dot, less, greater, minus, star, slash


		// Multiple char tokens
		case int, float, identifier, equalEqual, bangEqual, lessEqual, greaterEqual, string

		// Keywords
		case `func`, `true`, `false`, `return`,
				 `if`, `in`, call, `else`,
				 `while`, `var`, `let`, initialize,
				 `struct`, `self`, `Self`, `import`

		case newline
		case eof
		case error
		case builtin
	}

	public let kind: Kind
	public let start: Int
	public let length: Int
	public let line: Int
	public let column: Int

	public let lexeme: String

	public var debugDescription: String {
		".\(kind)"
	}

	public static func synthetic(_ kind: Kind, lexeme: String? = nil ) -> Token {
		Token(
			kind: kind,
			start: 0,
			length: 0,
			line: 0,
			column: 0,
			lexeme: lexeme ?? "\(kind)"
		)
	}
}

public struct TalkTalkLexer {
	let source: ContiguousArray<Character>

	var start = 0
	var current = 0

	var line = 0
	var column = 0

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
		case ":": make(.colon)
		case ".": make(.dot)
		case "-": make(.minus)
		case "<": make(match("=") ? .lessEqual : .less)
		case ">": make(match("=") ? .greaterEqual : .greater)
		case "\"": string()
		case _ where char.isNewline: newline()
		case _ where char.isMathSymbol: symbol()
		case _ where char.isNumber: number()
		default:
			if char.isLetter || char == "_" {
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

	mutating func string() -> Token {
		while !isAtEnd, peek() != "\"" {
			advance()
		}

		advance()

		return make(.string)
	}

	mutating func newline() -> Token {
		nextLine()

		while !isAtEnd, peek().isNewline {
			advance()
			nextLine()
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
		case "var": make(.var)
		case "let": make(.let)
		case "struct": make(.struct)
		case "return": make(.return)
		case "import": make(.import)
		case "init": make(.initialize)
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
			column += 1
			current += 1
		}

		return source[current]
	}

	mutating func make(_ kind: Token.Kind) -> Token {
		let length = current - start
		return Token(
			kind: kind,
			start: start,
			length: length,
			line: line,
			column: kind == .eof ? column : column - length,
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

	mutating func nextLine() {
		line += 1
		column = 0
	}
}
