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

		static func +(lhs: Precedence, rhs: Byte) -> Precedence {
			Precedence(rawValue: lhs.rawValue + rhs) ?? .any
		}

		case none,
				 assignment, 	// =
				 `or`,				// ||
				 `and`,				// &&
				 equality,		// == !=
				 comparison,	// < > <= >=
				 term,				// + -
				 factor,			// * /
				 unary,				// ! -
				 call,				// . ()
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
		self.previous = current
		while true {
			self.current = lexer.next()

			if case let .error(message) = current.kind {
				error(at: current, message)
				continue
			}

			break
		}
	}

	mutating func consume(_ kind: Token.Kind, _ message: String) {
		if current.kind == kind {
			advance()
			return
		}

		error(at: current, "Unexpected token: \(current as Any). Expected: \(kind).")
	}

	mutating func error(at token: Token, _ message: String) {
		print("Parser Error: \(token), message: \(message)")
		self.errors.append(Error(token: token, message: message))
	}
}
