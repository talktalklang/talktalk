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
	var isInFunction = false
	public var errors: [(Token, String)] = []

	public static func parse(_ string: String) -> [any Expr] {
		var parser = Parser(Lexer(string))
		return parser.parse()
	}

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
		if match(.identifier) {
			return VarExprSyntax(token: previous)
		}

		if match(.int) {
			let int = Int(previous.lexeme)!
			return LiteralExprSyntax(value: .int(int))
		}

		if match(.true) {
			return LiteralExprSyntax(value: .bool(true))
		}

		if match(.false) {
			return LiteralExprSyntax(value: .bool(false))
		}

		if match(.leftParen) {
			return expression()
		}

		advance()
		return error(at: previous, "Parser: Unexpected token: \(previous!)")
	}

	mutating func defExpr() -> Expr {
		guard let name = consume(.identifier) else {
			return error(at: current, "Expected identifier")
		}

		let expr = expr()

		_ = consume(.rightParen)

		return DefExprSyntax(name: name, value: expr)
	}

	mutating func expression() -> Expr {
		if match(.def) {
			return defExpr()
		}

		if match(.call) {
			return callExpr()
		}

		if match(.identifier) {
			return callOrFuncExpr()
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

	mutating func callOrFuncExpr() -> Expr {
		var parameters: [Token] = [previous]

		while match(.identifier) {
			parameters.append(previous)
		}

		if match(.in) {
			return funcExpr(parameters: parameters)
		}

		// It's not a func, so convert the prior identifiers to var exprs
		var operands: [any Expr] = parameters[1 ..< parameters.count].map { VarExprSyntax(token: $0) }
		while !check(.rightParen), !check(.eof) {
			operands.append(expr())
		}

		consume(.rightParen)

		return CallExprSyntax(op: parameters[0], args: operands)
	}

	mutating func funcExpr(parameters: [Token]) -> Expr {
		var body: [any Expr] = []

		while !check(.rightParen), !check(.eof) {
			body.append(expr())
		}
		_ = consume(.rightParen)

		return FuncExprSyntax(params: ParamsExprSyntax(names: parameters.map(\.lexeme)), body: body, i: previous.start)
	}

	mutating func addExpr() -> Expr {
		let lhs = expr()
		let rhs = expr()

		_ = consume(.rightParen)

		return AddExprSyntax(lhs: lhs, rhs: rhs)
	}

	mutating func callExpr() -> Expr {
		let op = previous!
		var operands: [Expr] = []

		while !check(.rightParen), !check(.eof) {
			operands.append(expr())
		}

		_ = consume(.rightParen)

		return CallExprSyntax(op: op, args: operands)
	}

	mutating func ifExpr() -> Expr {
		let condition = expr()
		let consequence = expr()
		let alternative = expr()

		_ = consume(.rightParen)

		return IfExprSyntax(
			condition: condition,
			consequence: consequence,
			alternative: alternative
		)
	}

	mutating func advance() {
		previous = current
		current = lexer.next()
	}

	@discardableResult mutating func consume(_ kind: Token.Kind) -> Token? {
		if peek().kind == kind {
			defer {
				advance()
			}

			return peek()
		}

		_ = error(at: peek(), "Expected \(kind), got \(peek())")
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
		return ErrorExprSyntax(message: message)
	}
}
