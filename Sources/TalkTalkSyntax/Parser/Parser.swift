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
	enum ParserError: Error {
		case couldNotParse([SyntaxError])
	}

	var parserRepeats: [Int: Int] = [:]

	var lexer: Lexer
	var current: Token
	var previous: Token!
	var lastID = 0

	// The location stack is used for tracking source locations while parsing
	var locationStack: SourceLocationStack = .init()

	public var errors: [SyntaxError] = []

	public static func parse(_ source: SourceFile, allowErrors: Bool = false) throws -> [any Syntax] {
		var parser = Parser(Lexer(source))
		let result = parser.parse()
		if !parser.errors.isEmpty {
			if !allowErrors {
				throw ParserError.couldNotParse(parser.errors)
			}
		}
		return result
	}

	public init(_ lexer: Lexer) {
		var lexer = lexer
		self.previous = lexer.next()
		self.current = previous
		self.lexer = lexer
		self.errors = lexer.errors
	}

	mutating func nextID() -> SyntaxID {
		defer { lastID += 1 }
		return lastID
	}

	public mutating func parse() -> [any Syntax] {
		var results: [any Syntax] = []
		skip(.newline)

		while current.kind != .eof {
			skip(.newline)

			results.append(decl())

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

	mutating func decl() -> any Syntax {
		if didMatch(.struct) {
			return structDecl()
		}

		if didMatch(.protocol) {
			return protocolDecl()
		}

		if didMatch(.func) {
			return funcExpr()
		}

		if didMatch(.initialize) {
			return _init()
		}

		if didMatch(.var) {
			return letVarDecl(.var)
		}

		if didMatch(.let) {
			return letVarDecl(.let)
		}

		if didMatch(.initialize) {
			return _init()
		}

		return stmt()
	}

	mutating func expr() -> Expr {
		skip(.newline)
		return parse(precedence: .assignment)
	}

	mutating func stmt() -> any Stmt {
		skip(.semicolon)

		if didMatch(.import) {
			return importStmt()
		}

		if didMatch(.if) {
			return ifStmt()
		}

		if didMatch(.while) {
			return whileStmt()
		}

		if didMatch(.var) {
			return letVarDecl(.var)
		}

		if didMatch(.return) {
			return returning(false)
		}

		if didMatch(.let) {
			return letVarDecl(.let)
		}

		// At this level, we want an ExprStmt, not just a normal expr
		let expr = expr()
		return ExprStmtSyntax(id: nextID(), expr: expr, location: expr.location)
	}

	mutating func parameterList(terminator: Token.Kind = .rightParen) -> ParamsExprSyntax {
		let i = startLocation(at: previous)

		if didMatch(.rightParen) {
			return ParamsExprSyntax(id: nextID(), params: [], location: endLocation(i))
		}

		var params: [ParamSyntax] = []

		repeat {
			skip(.newline)
			guard let identifier = consume(.identifier) else {
				break
			}
			skip(.newline)
			var type: TypeExprSyntax? = nil

			if didMatch(.colon), let typeID = consume(.identifier) {
				let i = startLocation(at: previous!)

				var genericParamsSyntax: GenericParamsSyntax? = nil
				if didMatch(.less) {
					genericParamsSyntax = genericParams()
				}

				type = TypeExprSyntax(
					id: nextID(),
					identifier: typeID,
					genericParams: genericParamsSyntax,
					location: endLocation(i)
				)
			}
			skip(.newline)

			params.append(ParamSyntax(id: nextID(), name: identifier.lexeme, type: type, location: [identifier]))
		} while didMatch(.comma)

		consume(terminator, "Expected '\(terminator)' after parameter list")

		return ParamsExprSyntax(
			id: nextID(),
			params: params,
			location: endLocation(i)
		)
	}

	mutating func argumentList(terminator: Token.Kind = .rightParen) -> [CallArgument] {
		var args: [CallArgument] = []
		repeat {
			let i = startLocation()
			var name: Token?

			if check(.identifier), checkNext(.colon) {
				let identifier = consume(.identifier)!
				consume(.colon)
				name = identifier
			}

			let value = parse(precedence: .assignment)
			args.append(CallArgument(id: nextID(), location: endLocation(i), label: name, value: value))
		} while didMatch(.comma)

		consume(terminator, "expected '\(terminator)' after arguments")
		return args
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

	@discardableResult mutating func consume(_ kind: Token.Kind, _: String? = nil) -> Token? {
		checkForInfiniteLoop()

		if peek().kind == kind {
			defer {
				advance()
			}

			return peek()
		}

		_ = error(
			at: peek(),
			.unexpectedToken(expected: kind, got: peek()),
			expectation: .guess(from: kind)
		)
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

		_ = error(
			at: peek(),
			.unexpectedToken(expected: kind, got: peek()),
			expectation: .guess(from: kind)
		)
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

	mutating func error(at: Token, _ kind: SyntaxErrorKind, expectation: ParseExpectation) -> ParseError {
		errors.append(
			SyntaxError(
				line: at.line,
				column: at.column,
				kind: kind,
				syntax: nil
			)
		)

		return ParseErrorSyntax(location: [at], message: "\(kind)", expectation: expectation)
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

		if locationStack.locations.count != stackSize {
			print(
				"Location tracking leaked, started: \(stackSize), ended: \(locationStack.locations.count)")
		}

		return SourceLocation(
			path: start.path,
			start: start,
			end: previous
		)
	}
}
