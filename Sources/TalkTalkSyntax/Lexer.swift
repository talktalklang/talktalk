//
//  Lexer.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//
import Foundation

struct Lexer {
	var source: ContiguousArray<Character>
	var start: Int
	var current: Int
	var line = 1

	init(source: String) {
		self.source = ContiguousArray(source)
		self.start = 0
		self.current = 0
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
		current = 0
		start = 0
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

			result += "[\(token.start)] \(token.kind) \(String(source[token.start ..< token.start + token.length]))"
			result += "\n"

			lastLine = token.line
		}

		return result
	}

	mutating func next() -> Token {
		handleWhitespace()

		start = current

		if isAtEnd { return make(.eof) }

		let char = advance()
		return switch char {
		case "(": make(.leftParen)
		case ")": make(.rightParen)
		case "{": make(.leftBrace)
		case "}": make(.rightBrace)
		case "[": make(.leftBracket)
		case "]": make(.rightBracket)
		case ",": make(.comma)
		case ".": make(.dot)
		case "+": make(.plus)
		case ";": make(.semicolon)
		case "*": make(.star)
		case "/": make(.slash)
		case ":": make(.colon)
		case "-": make(match(">") ? .rightArrow : .minus)
		case "!": make(match("=") ? .bangEqual : .bang)
		case "=": make(match("=") ? .equalEqual : .equal)
		case "<": make(match("=") ? .lessEqual : .less)
		case ">": make(match("=") ? .greaterEqual : .greater)
		case "&": make(match("&") ? .andAnd : .and)
		case "|": make(match("|") ? .pipePipe : .pipe)
		case "\n": newline()
		case #"""#: string()
		case _ where char.isNumber: number()
		case _ where isIdentifier(char): identifier(start: char)
		default:
			error("Unexpected character: \(char.debugDescription)")
		}
	}

	mutating func handleWhitespace() {
		while let char = peek() {
			switch char {
			case " ", "\r", "\t":
				advance()
			case "/":
				if peekNext() == "/" {
					while peek() != "\n", !isAtEnd {
						advance()
					}
				} else {
					return
				}
			default:
				return
			}
		}
	}

	mutating func newline() -> Token {
		var count = 1

		while peek() == "\n" {
			count += 1
			advance()
		}

		defer {
			line += count
		}

		return make(.newline)
	}

	mutating func string() -> Token {
		while peek() != #"""# && !isAtEnd {
			if peek() == "\n" {
				line += 1
			}

			advance()
		}

		if isAtEnd {
			return error("Unterminated string.")
		}

		advance() // The closing quote

		return make(.string, lexeme: true)
	}

	mutating func number() -> Token {
		while let char = peek(), char.isNumber {
			advance()
		}

		if peek() == ".", let next = peekNext(), next.isNumber {
			// Consume the "."
			advance()

			while let char = peek(), char.isNumber {
				advance()
			}
		}

		return make(.number, lexeme: true)
	}

	mutating func identifier(start: Character) -> Token {
		var node = KeywordTrie.trie.root.lookup(start)

		while let char = peek(), isIdentifier(char) {
			advance()

			if let node = node.children[char],
			   let keyword = node.keyword,
			   !isIdentifier(peekNext())
			{
				return make(keyword, lexeme: true)
			}

			node = node.lookup(char)
		}

		if let keyword = node.keyword {
			return make(keyword)
		}

		return make(.identifier, lexeme: true)
	}

	func isIdentifier(_ char: Character?) -> Bool {
		guard let char else {
			return false
		}

		return char.isLetter || char.isNumber || char == "_"
	}

	func peek() -> Character? {
		if isAtEnd {
			return nil
		}

		return source[current]
	}

	func peekNext() -> Character? {
		if current > source.count - 2 {
			return nil
		}

		return source[current + 1]
	}

	mutating func match(_ char: Character) -> Bool {
		if isAtEnd { return false }

		if source[current] != char {
			return false
		}

		current += 1
		return true
	}

	@discardableResult mutating func advance() -> Character {
		let previous = current
		current = current + 1
		return source[previous]
	}

	func make(_ kind: Token.Kind, lexeme: Bool = false) -> Token {
		return Token(
			start: start,
			length: current - start,
			kind: kind,
			line: line,
			lexeme: lexeme ? String(source[start ..< current]) : nil
		)
	}

	func error(_ message: String) -> Token {
		make(.error(message))
	}

	var isAtEnd: Bool {
		current == source.count
	}
}
