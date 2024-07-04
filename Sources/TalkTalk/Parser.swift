//
//  Parser.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//
struct Parser: ~Copyable {
	enum Precedence: Byte, Comparable {
		static func < (lhs: Parser.Precedence, rhs: Parser.Precedence) -> Bool {
			lhs.rawValue < rhs.rawValue
		}

		static func + (lhs: Precedence, rhs: Byte) -> Precedence {
			Precedence(rawValue: lhs.rawValue + rhs) ?? .any
		}

		case none,
		     assignment, // =
		     or, // ||
		     and, // &&
		     equality, // == !=
		     comparison, // < > <= >=
		     term, // + -
		     factor, // * /
		     unary, // ! -
		     call, // . ()
		     primary,

		     any
	}

	struct Error {
		var token: Token
		var message: String
	}

	var lexer: Lexer
	var current: Token!
	var previous: Token!
	var errors: [Error] = []

	init(lexer: consuming Lexer) {
		let first = lexer.next()
		self.current = first
		self.lexer = lexer
	}

	mutating func advance() {
		previous = current
		while true {
			current = lexer.next()

			if case let .error(message) = current.kind {
				error(at: current, message)
				continue
			}

			break
		}
	}

	mutating func match(_ kind: Token.Kind) -> Bool {
		if !check(kind) {
			return false
		}

		advance()

		return true
	}

	func check(_ kind: Token.Kind) -> Bool {
		current.kind == kind
	}

	mutating func consume(_ kind: Token.Kind, _: String) {
		if current.kind == kind {
			advance()
			return
		}

		error(at: current, "Unexpected token: \(current.description(in: lexer.source)). Expected: \(kind).")
	}

	mutating func error(at token: Token, _ message: String) {
		errors.append(Error(token: token, message: message))
	}
}
