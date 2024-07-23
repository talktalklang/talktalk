//
//  Parser.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct Parser {
	var lexer: Lexer
	var current: Token
	public var errors: [(Token, String)] = []

	public init(_ lexer: Lexer) {
		var lexer = lexer
		self.current = lexer.next()
		self.lexer = lexer
	}

	public mutating func parse() -> Expr {
		if match(.leftParen) {
			return expression()
		} else if match(.def) {
			return defExpr()
		} else if check(.int) {
			let int = consume(.int)!
			return LiteralExpr(value: Int(int.lexeme)!)
		} else {
			error(at: current, "Unexpected token: \(current)")
			return ErrorExpr()
		}
	}

	mutating func defExpr() -> Expr {
		guard let name = consume(.identifier) else {
			error(at: current, "Expected identifier")
			return ErrorExpr()
		}

		let expr = parse()

		return DefExpr(name: name, expr: expr)
	}

	mutating func expression() -> Expr {
		var symbol: Symbol
		if let token = consume(.symbol) {
			symbol = Symbol(token: token)
		} else {
			print("No symbol, got \(current) instead")
			return ErrorExpr()
		}

		var operands: [Expr] = []
		while !check(.rightParen), !check(.eof) {
			operands.append(parse())
		}

		_ = consume(.rightParen)

		return VariadicExpr(op: symbol, operands: operands)
	}

	mutating func advance() {
		self.current = lexer.next()
	}

	mutating func consume(_ kind: Token.Kind) -> Token? {
		if peek().kind == kind {
			defer {
				advance()
			}

			return peek()
		}

		error(at: peek(), "Expected \(kind), got \(peek())")
		return nil
	}

	func check(_ kind: Token.Kind) -> Bool {
		peek().kind == kind
	}

	mutating func match(_ kind: Token.Kind) -> Bool {
		if peek().kind == kind {
			defer { advance() }

			return true
		}

		return false
	}

	func peek() -> Token {
		current
	}

	mutating func error(at: Token, _ message: String) {
		fatalError("Error at \(at): \(message)")
		errors.append((at, message))
	}
}
