//
//  Parser.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

struct SourceLocationStack {
	var locations: [Token] = []

	public mutating func push(_ token: Token) {
		locations.append(token)
	}

	public mutating func pop() -> Token? {
		locations.popLast()
	}
}

public struct Parser {
	var parserRepeats: [Int: Int] = [:]

	var lexer: TalkTalkLexer
	var current: Token
	var previous: Token!

	// The location stack is used for tracking source locations while parsing
	var locationStack: SourceLocationStack = .init()

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
		var results: [any Expr] = []
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

	mutating func decl() -> Decl {
		if didMatch(.func) {
			return funcExpr()
		}

		if didMatch(.var) {
			return letVarDecl(.var)
		}

		if didMatch(.let) {
			return letVarDecl(.let)
		}

		return SyntaxError(location: [current], message: "Expected declaration", expectation: .decl)
	}

	mutating func expr() -> Expr {
		skip(.newline)
		return parse(precedence: .assignment)
	}

	mutating func parameterList() -> ParamsExpr {
		let i = startLocation(at: previous)

		if didMatch(.rightParen) {
			return ParamsExprSyntax(params: [], location: endLocation(i))
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

		return ParamsExprSyntax(
			params: params.map { ParamSyntax(name: $0.lexeme, location: [$0]) },
			location: endLocation(i)
		)
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

		_ = error(at: peek(), message ?? "Expected \(kind), got \(peek().debugDescription)", expectation: .guess(from: kind))
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

		_ = error(at: peek(), "Expected \(kind), got \(peek().debugDescription)", expectation: .guess(from: kind))
		return false
	}

	func check(_ kind: Token.Kind) -> Bool {
		peek().kind == kind
	}

	func checkNext(_ kind: Token.Kind) -> Bool {
		var copy = self
		copy.advance()
		return copy.check(kind)
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

	mutating func error(at: Token, _ message: String, expectation: ParseExpectation) -> ErrorSyntax {
		errors.append((at, message))
		print(message, "ln: \(at.line) col: \(at.column)")
		return SyntaxError(location: [at], message: message, expectation: expectation)
	}

	mutating func startLocation(at token: Token? = nil) -> Int {
		defer {
			locationStack.push(token ?? current)
		}

		return locationStack.locations.count
	}

	mutating func endLocation(_ stackSize: Int) -> SourceLocation {
		guard let start = locationStack.pop() else {
			fatalError("Did not start location!")
		}

		assert(locationStack.locations.count == stackSize, "Location tracking leaked, started: \(stackSize), ended: \(locationStack.locations.count)")

		return SourceLocation(start: start, end: current)
	}
}
