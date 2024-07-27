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

	var exprLength = 0

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
			skip(.newline)
			results.append(expr())
			skip(.newline)
		}
		return results
	}

	public mutating func exprs() -> [any Expr] {
		var results: [any Expr] = []
		while !check(.rightParen), !check(.eof) {
			skip(.newline)
			results.append(expr())
			skip(.newline)
		}
		return results
	}

	mutating func expr() -> Expr {
		skip(.newline)
		exprLength += 1

		if match(.def) {
			return defExpr()
		}

		if match(.identifier) {
			return identifier()
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

		if match(.call) {
			return callExpr()
		}

		if match(.if) {
			return ifExpr()
		}

		if match(.plus) {
			return addExpr()
		}

		if match(.leftParen) {
			exprLength = 0
			skip(.newline)
			let expr = expr()
			skip(.newline)
			consume(.rightParen)
			skip(.newline)
			return expr
		}

		// If we haven't found anything else, move forward (to not infinite loop)
		// and return an error token.
		advance()
		return error(at: previous, "Parser: Unexpected token: \(previous!.debugDescription)")
	}

	mutating func defExpr() -> Expr {
		guard let name = consume(.identifier) else {
			return error(at: current, "Expected identifier")
		}

		let expr = expr()

		return DefExprSyntax(name: name, value: expr)
	}

	func upcoming(_ type: Token.Kind) -> Bool {
		var copy = self
		while !copy.check(.eof), !copy.check(.rightParen) {
			if copy.check(type) {
				return true
			}

			copy.advance()
		}
		return false
	}

	mutating func identifier() -> Expr {
		if !upcoming(.in), exprLength != 1 {
			return VarExprSyntax(token: previous)
		}

		skip(.newline)

		var parameters: [Token] = [previous]

		while match(.identifier) {
			parameters.append(previous)
		}

		skip(.newline)

		if match(.in) {
			skip(.newline)
			return funcExpr(parameters: parameters)
		}

		// If we started with an identifier and we're not in a function, it's a call. Add
		// the existing identifiers we've got as arguments, then see if there are any more.
		let callee = VarExprSyntax(token: parameters[0])
		var args: [any Expr] = parameters[1 ..< parameters.count].map { VarExprSyntax(token: $0) }

		while !check(.rightParen), !check(.eof) {
			args.append(expr())
		}

		return CallExprSyntax(callee: callee, args: args)
	}

	mutating func funcExpr(parameters: [Token]) -> Expr {
		var body: [any Expr] = []

		while !check(.eof), !check(.rightParen) {
			body.append(expr())
		}

		return FuncExprSyntax(params: ParamsExprSyntax(names: parameters.map(\.lexeme).map { ParamSyntax(name: $0) }), body: body, i: previous.start)
	}

	mutating func addExpr() -> Expr {
		let lhs = expr()
		let rhs = expr()

		return AddExprSyntax(lhs: lhs, rhs: rhs)
	}

	mutating func callExpr() -> Expr {
		let callee = expr()
		let args = exprs()
		return CallExprSyntax(callee: callee, args: args)
	}

	mutating func ifExpr() -> Expr {
		let condition = expr()
		let consequence = expr()
		let alternative = expr()

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

		_ = error(at: peek(), "Expected \(kind), got \(peek().debugDescription)")
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

	mutating func skip(_ kinds: Token.Kind...) {
		while kinds.contains(peek().kind), current.kind != .eof {
			advance()
		}
	}

	func peek() -> Token {
		current
	}

	mutating func error(at: Token, _ message: String) -> ErrorExpr {
		errors.append((at, message))
		return ErrorExprSyntax(message: message)
	}
}
