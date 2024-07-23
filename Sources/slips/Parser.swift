//
//  Parser.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct Parser {
	var lexer: Lexer
	var current: Token
	var previous: Token!
	public var errors: [(Token, String)] = []

	public init(_ lexer: Lexer) {
		var lexer = lexer
		self.previous = lexer.next()
		self.current = previous
		self.lexer = lexer
	}

	public mutating func parse() -> [Expr] {
		var results: [Expr] = []
		while current.kind != .eof {
			results.append(expr())
		}
		return results
	}

	mutating func expr() -> Expr {
		if match(.int) {
			let int = Int(previous.lexeme)!
			return LiteralExpr(value: .int(int))
		} else if match(.string) {
			let str = String(previous.lexeme.dropFirst().dropLast())
			return LiteralExpr(value: .string(str))
		} else if match(.identifier) {
			return VarExpr(token: previous)
		} else if match(.true) {
			return LiteralExpr(value: .bool(true))
		} else if match(.false) {
			return LiteralExpr(value: .bool(false))
		} else if match(.leftParen) {
			return expression()
		} else {
			advance()
			return error(at: previous, "Unexpected token: \(previous!)")
		}
	}

	mutating func defExpr() -> Expr {
		guard let name = consume(.identifier) else {
			return error(at: current, "Expected identifier")
		}

		let expr = expr()

		_ = consume(.rightParen)

		return DefExpr(name: name, expr: expr)
	}

	mutating func expression() -> Expr {
		print("expression() , current -> \(current)")

		if match(.def) {
			return defExpr()
		}

		if match(.identifier) {
			return callExpr()
		}

		if match(.if) {
			return ifExpr()
		}

		if match(.plus) {
			return addExpr()
		}

		let expr = expr()

		_ = consume(.rightParen)

		return expr
	}

	mutating func addExpr() -> Expr {
		var operands: [Expr] = []

		while !check(.rightParen), !check(.eof) {
			operands.append(expr())
		}

		_ = consume(.rightParen)

		return AddExpr(operands: operands)
	}

	mutating func callExpr() -> Expr {
		let op = previous!
		var operands: [Expr] = []

		while !check(.rightParen), !check(.eof) {
			operands.append(expr())
		}

		_ = consume(.rightParen)

		return CallExpr(op: op, args: operands)
	}

	mutating func ifExpr() -> Expr {
		let condition = expr()
		let consequence = expr()
		let alternative = expr()

		_ = consume(.rightParen)

		return IfExpr(
			condition: condition,
			consequence: consequence,
			alternative: alternative
		)
	}

	mutating func advance() {
		previous = current
		current = lexer.next()
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

	mutating func error(at: Token, _ message: String) -> ErrorExpr {
		errors.append((at, message))
		return ErrorExpr(message: message)
	}
}
