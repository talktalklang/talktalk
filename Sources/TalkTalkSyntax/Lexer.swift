//
//  Lexer.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//
import Foundation

public struct Token: CustomDebugStringConvertible, Sendable, Equatable, Hashable, Codable {
	public enum Kind: Sendable, Equatable, Hashable, Codable {
		// Single char tokens
		case leftParen, rightParen,
		     leftBrace, rightBrace,
		     leftBracket, rightBracket,
		     semicolon, symbol, plus, equals, comma, bang,
		     colon, dot, less, greater, minus, star, slash

		// Multiple char tokens
		case int, float, identifier, equalEqual, bangEqual, lessEqual, greaterEqual, string, forwardArrow,
		     plusEquals, minusEquals

		// String interpolation
		case interpolationStart, interpolationEnd

		// Keywords
		case `func`, `true`, `false`, `return`,
		     `if`, `in`, call, `else`,
		     `while`, `var`, `let`, initialize,
		     `struct`, `self`, `Self`, `import`, `is`, `protocol`,
		     `enum`, match, `case`, `for`

		case newline
		case eof
		case error
		case builtin
		case comment
	}

	public let path: String
	public let kind: Kind
	public let start: Int
	public let length: Int
	public let line: Int
	public let column: Int

	public let lexeme: String

	public var end: Int {
		start + length
	}

	public var debugDescription: String {
		"Token(kind: .\(kind), start: \(start), path: \(path), line: \(line), column: \(column), position: \(start), length: \(length), lexeme: \(lexeme.debugDescription))"
	}

	public static func synthetic(_ kind: Kind, lexeme: String? = nil) -> Token {
		Token(
			path: "synthetic",
			kind: kind,
			start: 0,
			length: 0,
			line: 0,
			column: 0,
			lexeme: lexeme ?? "\(kind)"
		)
	}
}

public struct Lexer {
	let path: String
	let source: ContiguousArray<Character>

	var start = 0
	var current = 0

	var line = 0
	var column = 0

	var errors: [SyntaxError]
	var nextBuffer: [Token] = []

	// Comment handling (disabled by default)
	var preserveComments: Bool
	var comments: [Token] = []

	public init(_ source: SourceFile, preserveComments: Bool = false) {
		self.path = source.path
		self.source = ContiguousArray<Character>(source.text)
		self.errors = []
		self.preserveComments = preserveComments

		if source.path.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
			#if DEBUG
				print("empty source path is discouraged")
				raise(SIGINT)
			#endif
		}
	}

	public static func collect(_ file: SourceFile) -> [Token] {
		var lexer = Lexer(file)
		return lexer.collect()
	}

	public mutating func rewind(count _: Int) {}

	public mutating func next(terminator: Character? = nil) -> Token {
		// When parsing interpolated strings, we may need to buffer tokens for the interpolated
		// expressions. If we've done that, we want to empty that buffer first.
		if !nextBuffer.isEmpty { return nextBuffer.removeFirst() }

		skipWhitespace()

		if preserveComments {
			saveComments()
		} else {
			skipComments()
		}

		if isAtEnd {
			return make(.eof)
		}

		start = current

		let char = advance()

		if let terminator, char == terminator {
			return make(.eof)
		}

		return switch char {
		case "(": make(.leftParen)
		case ")": make(.rightParen)
		case "{": make(.leftBrace)
		case "}": make(.rightBrace)
		case "[": make(.leftBracket)
		case "]": make(.rightBracket)
		case "=": make(match("=") ? .equalEqual : .equals)
		case "!": make(match("=") ? .bangEqual : .bang)
		case "*": make(.star)
		case "/": make(.slash)
		case "+": make(match("=") ? .plusEquals : .plus)
		case ",": make(.comma)
		case ":": make(.colon)
		case ".": make(.dot)
		case ";": make(.semicolon)
		case "-": minus()
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

	mutating func minus() -> Token {
		if match(">") {
			return make(.forwardArrow)
		}

		if match("=") {
			return make(.minusEquals)
		}

		return make(.minus)
	}

	mutating func string() -> Token {
		let stringStart = current

		while peek() != "\"" {
			if isAtEnd {
				error("unterminated string literal")
				return make(.string)
			}

			// When we encounter the escape char (\), it's either string interpolation
			// or an escape sequence.
			if peek() == "\\" {
				if peekNext() == "(" {
					stringInterpolation(start: stringStart)
					continue
				}

				advance()
			}

			advance()

			if isAtEnd {
				error("unterminated string literal")
				return make(.string)
			}
		}

		advance()

		nextBuffer.append(make(.string))
		let returnToken = nextBuffer.removeFirst()

		return returnToken
	}

	mutating func stringInterpolation(start _: Int) {
		var buffer: [Token] = []

		buffer.append(make(.string))

		start = current
		advance() // Consume '\'
		advance() // Consume '('

		// Save the interpolation start.
		buffer.append(make(.interpolationStart))

		var next = next(terminator: ")")
		while next.kind != .eof {
			buffer.append(next)
			next = self.next(terminator: ")")
		}

		// Add the end of the interpolation to the buffer
		buffer.append(make(.interpolationEnd))

		start = current

		nextBuffer.append(contentsOf: buffer)
	}

	mutating func newline() -> Token {
		nextLine()

		while !isAtEnd, check(\.isNewline) {
			advance()
			nextLine()
		}

		let newline = make(.newline)

		return newline
	}

	mutating func identifier() -> Token {
		while !isAtEnd, check(\.isLetter) || check(\.isNumber) || peek() == "_" {
			advance()
		}

		return switch String(source[start ..< current]) {
		case "func": make(.func)
		case "true": make(.true)
		case "false": make(.false)
		case "if": make(.if)
		case "else": make(.else)
		case "is": make(.is)
		case "in": make(.in)
		case "call": make(.call)
		case "while": make(.while)
		case "var": make(.var)
		case "let": make(.let)
		case "struct": make(.struct)
		case "return": make(.return)
		case "import": make(.import)
		case "init": make(.initialize)
		case "protocol": make(.protocol)
		case "enum": make(.enum)
		case "match": make(.match)
		case "case": make(.case)
		case "for": make(.for)
		default:
			make(.identifier)
		}
	}

	mutating func symbol() -> Token {
		while check(\.isMathSymbol), !isAtEnd {
			advance()
		}

		return make(.symbol)
	}

	mutating func number() -> Token {
		var isFloat = false

		while !isAtEnd, check(\.isNumber) || (!isFloat && peek() == ".") {
			if peek() == "." {
				isFloat = true
			}

			advance()
		}

		return make(isFloat ? .float : .int)
	}

	// MARK: Helpers

	mutating func skipWhitespace() {
		while !isAtEnd, check(\.isWhitespace), !check(\.isNewline) {
			advance()
		}
	}

	mutating func saveComments() {
		if peek() == "/", peekNext() == "/" {
			start = current

			while !isAtEnd, peek() != "\n" {
				advance()
			}

			comments.append(
				make(.comment)
			)
		}
	}

	mutating func skipComments() {
		if peek() == "/", peekNext() == "/" {
			while !isAtEnd, peek() != "\n" {
				advance()
			}
		}
	}

	mutating func match(_ char: Character) -> Bool {
		if peek() == char {
			advance()
			return true
		}

		return false
	}

	func peek() -> Character? {
		if isAtEnd { return nil }

		return source[current]
	}

	func peekNext() -> Character? {
		if current > source.count - 2 {
			return nil
		}

		return source[current + 1]
	}

	@discardableResult mutating func advance() -> Character {
		defer {
			column += 1
			current += 1
		}

		if source.indices.contains(current) {
			return source[current]
		} else {
			return Character("\0")
		}
	}

	mutating func make(_ kind: Token.Kind) -> Token {
		let length = current - start

		return Token(
			path: path,
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

	func check(_ keypath: KeyPath<Character, Bool>) -> Bool {
		guard let peek = peek() else {
			return false
		}

		return peek[keyPath: keypath]
	}

	@discardableResult mutating func error(_ message: String) -> Token {
		errors.append(
			.init(
				line: line,
				column: column,
				kind: .lexerError(message)
			)
		)
		return make(.error)
	}

	mutating func nextLine() {
		line += 1
		column = 0
	}
}
