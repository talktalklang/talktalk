//
//  Parser.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct Parser {
	var parserRepeats: [Int: Int] = [:]

	var lexer: TalkTalkLexer
	var current: Token
	var previous: Token!

	var exprLength = 0

	public var errors: [(Token, String)] = []

	public static func parse(_ string: String) -> [any Expr] {
		var parser = Parser(TalkTalkLexer(string))
		return parser.parse()
	}

	public init(_ lexer: TalkTalkLexer) {
		var lexer = lexer
		self.previous = lexer.next()
		self.current = previous
		self.lexer = lexer
	}

	var results: [Expr] = []
	public mutating func parse() -> [Expr] {
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
		return parse(precedence: .assignment)
	}

	mutating func funcExpr() -> Expr {
		// Grab the name if there is one
		let name: Token? = match(.identifier)

		skip(.newline)

		consume(.leftParen, "expected '(' before params")

		// Parse parameter list
		let params = parameterList()

		skip(.newline)

		guard didConsume(.leftBrace) else {
			return ErrorExprSyntax(message: "expected '{' before func body")
		}

		var body: [any Expr] = []
		while !check(.eof), !check(.rightBrace) {
			skip(.newline)
			body.append(expr())
			skip(.newline)
		}

		consume(.rightBrace, "Expected '}' after func body")

		return FuncExprSyntax(params: params, body: body, i: lexer.current, name: name?.lexeme)
	}

	mutating func parameterList() -> ParamsExpr {
		if didMatch(.rightParen) {
			return ParamsExprSyntax(params: [])
		}

		var params: [Token] = []

		repeat {
			skip(.newline)
			guard let identifier = consume(.identifier) else {
				break
			}
			skip(.newline)

			params.append(identifier)
		} while didMatch(.comma)

		consume(.rightParen, "Expected ')' after parameter list")

		return ParamsExprSyntax(params: params.map { ParamSyntax(name: $0.lexeme) })
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

		while didMatch(.identifier) {
			parameters.append(previous)
		}

		skip(.newline)

		if didMatch(.in) {
			skip(.newline)
			return funcExpr()
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

	mutating func addExpr() -> Expr {
		let lhs = expr()
		let rhs = expr()

		return BinaryExprSyntax(lhs: lhs, rhs: rhs, op: .plus)
	}

	mutating func callExpr() -> Expr {
		let callee = expr()
		let args = exprs()
		return CallExprSyntax(callee: callee, args: args)
	}

	mutating func ifExpr() -> Expr {
		let condition = expr()
		let consequence = blockExpr(false)
		let alternative = blockExpr(false)

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

	@discardableResult mutating func consume(_ kind: Token.Kind, _ message: String? = nil) -> Token? {
		checkForInfiniteLoop()

		if peek().kind == kind {
			defer {
				advance()
			}

			return peek()
		}

		_ = error(at: peek(), message ?? "Expected \(kind), got \(peek().debugDescription)")
		return nil
	}

	@discardableResult mutating func didConsume(_ kind: Token.Kind) -> Bool {
		checkForInfiniteLoop()

		if peek().kind == kind {
			defer {
				advance()
			}

			return true
		}

		_ = error(at: peek(), "Expected \(kind), got \(peek().debugDescription)")
		return false
	}

	func check(_ kind: Token.Kind) -> Bool {
		peek().kind == kind
	}

	mutating func didMatch(_ kind: Token.Kind) -> Bool {
		checkForInfiniteLoop()

		if peek().kind == kind {
			defer { advance() }

			return true
		}

		return false
	}

	mutating func match(_ kind: Token.Kind) -> Token? {
		checkForInfiniteLoop()

		if peek().kind == kind {
			defer { advance() }

			return peek()
		}

		return nil
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
		print(message)
		return ErrorExprSyntax(message: message)
	}
}
