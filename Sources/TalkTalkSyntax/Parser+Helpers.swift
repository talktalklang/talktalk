//
//  Parser+Helpers.swift
//  
//
//  Created by Pat Nakajima on 7/8/24.
//
extension Parser {
	mutating func match(_ kind: Token.Kind) -> Bool {
		if check(kind) {
			advance()
			return true
		}

		return false
	}

	mutating func match(_ kinds: Token.Kinds) -> Bool {
		if check(kinds) {
			advance()
			return true
		}

		return false
	}


	mutating func check(_ kind: Token.Kind) -> Bool {
		return current.kind == kind
	}

	mutating func advance() {
		self.current = lexer.next()
	}

	mutating func skip(_ kind: Token.Kind) {
		while check(kind), current.kind != .eof {
			advance()
		}
	}

	mutating func skip(_ kinds: Token.Kinds) {
		while check(kinds), current.kind != .eof {
			advance()
		}
	}

	mutating func check(_ kinds: Token.Kinds) -> Bool {
		return kinds.contains(current.kind)
	}

	mutating func consume<T: Consumable>(_ token: Token, as: T.Type) -> T? {
		if let result = T.consuming(token) {
			advance()
			return result
		}

		error("Expected \(T.self), got \(token.kind)", at: current)

		return nil
	}

	mutating func consume(_ kinds: Token.Kinds, _: String) {
		if kinds.contains(current.kind) {
			advance()
			return
		}

		let kinds = kinds.map { "\($0)".components(separatedBy: ".").last! }.joined(separator: ", ")
		error("Unexpected token: \(current.description(in: lexer.source)). Expected: \(kinds).", at: current)
	}

	mutating func consume(_ kind: Token.Kind, _: String) {
		if current.kind == kind {
			advance()
			return
		}

		let kind = "\(kind)".components(separatedBy: ".").last!
		error("Unexpected token: \(current.description(in: lexer.source)). Expected: \(kind).", at: current)
	}

	mutating func line(_ number: Int) -> String {
		let lines = String(lexer.source).components(separatedBy: "\n")
		if number >= lines.count {
			return "EOF"
		} else {
			return lines[number]
		}
	}

	mutating func error(_ message: String, at token: Token) {
		errors.append(Error(token: token, message: message))
	}
}
