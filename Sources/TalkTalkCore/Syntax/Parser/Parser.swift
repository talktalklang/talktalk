//
//  Parser.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import Foundation

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
	public enum ParserError: Error, LocalizedError {
		case couldNotParse([SyntaxError])

		public var errorDescription: String? {
			switch self {
			case let .couldNotParse(array):
				array.map { "\($0)" }.joined(separator: ", ")
			}
		}
	}

	var parserRepeats: [Int: Int] = [:]

	var lexer: Lexer
	var current: Token
	var previous: Token!
	var previousBeforeNewline: Token?
	var lastID = 0

	// The location stack is used for tracking source locations while parsing
	var locationStack: SourceLocationStack = .init()

	public var errors: [SyntaxError] = []

	public static func parseFile(_ sourceFile: SourceFile, allowErrors: Bool = false) throws -> ParsedSourceFile {
		try ParsedSourceFile(path: sourceFile.path, syntax: parse(sourceFile, allowErrors: allowErrors))
	}

	public static func parse(_ source: SourceFile, allowErrors: Bool = false, preserveComments: Bool = false) throws -> [any Syntax] {
		var parser = Parser(Lexer(source, preserveComments: preserveComments))
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

	public var comments: [Token] {
		lexer.comments
	}

	mutating func nextID() -> SyntaxID {
		defer { lastID += 1 }
		return SyntaxID(id: lastID, path: lexer.path)
	}

	mutating func synchronize() {
		advance()

		while !lexer.isAtEnd {
			if previous.kind == .newline {
				break
			}

			switch peek().kind {
			case .struct,
			     .enum,
			     .func,
			     .var,
			     .let,
			     .if,
			     .while,
			     .for,
			     .return:
				break
			default:
				advance()
			}
		}
	}

	public mutating func parse() -> [any Syntax] {
		var results: [any Syntax] = []
		skip(.newline)

		while current.kind != .eof {
			skip(.newline)

			let decl = decl(context: .topLevel)
			results.append(decl)

			if decl is ParseErrorSyntax {
				synchronize()
			}

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

	mutating func decl(context: DeclContext) -> any Syntax {
		if didMatch(.enum), context.allowed.contains(.enum) {
			return enumDecl()
		}

		if didMatch(.struct), context.allowed.contains(.struct) {
			return structDecl()
		}

		if didMatch(.protocol), context.allowed.contains(.protocol) {
			return protocolDecl()
		}

		if let staticKeyword = match(.static), context.allowed.contains(.static) {
			if check(.func), didConsume(.func) {
				return methodDecl(isStatic: true, modifiers: [staticKeyword])
			}

			if check(.var), didConsume(.var) {
				if context == .struct {
					return propertyDecl(previous, isStatic: true, modifiers: [staticKeyword])
				} else {
					return letVarDecl(.var, isStatic: true, modifiers: [staticKeyword])
				}
			}

			if check(.let), didConsume(.let) {
				if context == .struct {
					return propertyDecl(previous, isStatic: true, modifiers: [staticKeyword])
				} else {
					return letVarDecl(.let, isStatic: true, modifiers: [staticKeyword])
				}
			}
		}

		if didMatch(.func), context.allowed.contains(.func) {
			if context.isLexicalScopeBody {
				return methodDecl(isStatic: false)
			} else {
				return funcExpr(isStatic: false)
			}
		}

		if didMatch(.case), context.allowed.contains(.case) {
			return enumCaseDecl()
		}

		if didMatch(.initialize), context.allowed.contains(.initialize) {
			return _init()
		}

		if didMatch(.var), context.allowed.contains(.var) {
			if context == .struct {
				return propertyDecl(previous, isStatic: false, modifiers: [])
			} else {
				return letVarDecl(.var, isStatic: false)
			}
		}

		if didMatch(.let), context.allowed.contains(.let) {
			if context == .struct {
				return propertyDecl(previous, isStatic: false, modifiers: [])
			} else {
				return letVarDecl(.let, isStatic: false)
			}
		}

		if context == .argument {
			// If we're parsing an argument, we just want to return an expression here.
			return expr()
		} else {
			// Otherwise allow statements.
			return stmt()
		}
	}

	mutating func expr() -> Expr {
		skip(.newline)
		return parse(precedence: .assignment)
	}

	mutating func stmt() -> any Stmt {
		skip(.semicolon)

		if didMatch(.match) {
			return matchStmt()
		}

		if didMatch(.for) {
			return forStmt()
		}

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
			return letVarDecl(.var, isStatic: false)
		}

		if didMatch(.let) {
			return letVarDecl(.let, isStatic: false)
		}

		if didMatch(.return) {
			return returning(false)
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
				// swiftlint:disable force_unwrapping
				let i = startLocation(at: previous!)
				// swiftlint:enable force_unwrapping

				var typeParameters: [TypeExprSyntax] = []
				if didMatch(.less) {
					typeParameters = self.typeParameters()
				}

				let isOptional = didMatch(.questionMark)

				type = TypeExprSyntax(
					id: nextID(),
					identifier: typeID,
					genericParams: typeParameters,
					isOptional: isOptional,
					location: endLocation(i)
				)
			}
			skip(.newline)

			params.append(ParamSyntax(id: nextID(), name: identifier.lexeme, type: type, location: [identifier]))
		} while didMatch(.comma)

		consume(terminator)

		return ParamsExprSyntax(
			id: nextID(),
			params: params,
			location: endLocation(i)
		)
	}

	mutating func argumentList(terminator: Token.Kind = .rightParen) -> [Argument] {
		var args: [Argument] = []
		skip(.newline)
		repeat {
			let i = startLocation()
			var name: Token?

			if check(.identifier), checkNext(.colon) {
				skip(.newline)
				let identifier = consume(.identifier).unsafelyUnwrapped
				skip(.newline)
				consume(.colon)
				skip(.newline)
				name = identifier
			}

			let value = decl(context: .argument)
			skip(.newline)
			args.append(Argument(id: nextID(), location: endLocation(i), label: name, value: value))
		} while didMatch(.comma)

		skip(.newline)
		consume(terminator)
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

		if previous.kind != .newline {
			previousBeforeNewline = previous
		}
	}

	@discardableResult mutating func consume(_ kinds: Token.Kind...) -> Token? {
		checkForInfiniteLoop()

		if kinds.contains(peek().kind) {
			defer {
				advance()
			}

			return peek()
		}

		_ = error(
			at: peek(),
			.unexpectedToken(expected: kinds[0], got: peek()),
			expectation: .guess(from: kinds[0])
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

	func check(_ kinds: Set<Token.Kind>) -> Bool {
		kinds.contains(peek().kind)
	}

	func check(_ kinds: Token.Kind...) -> Bool {
		kinds.contains(peek().kind)
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

	mutating func match(_ kind: Set<Token.Kind>) -> Token? {
		checkForInfiniteLoop()

		if kind.contains(peek().kind) {
			defer { advance() }

			return peek()
		}

		return nil
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

	mutating func error(at: Token, _ kind: SyntaxErrorKind, expectation: ParseExpectation = .none) -> ParseError {
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
			print("Did not start location!")
			return [.synthetic(.bang)]
		}

		if locationStack.locations.count != stackSize {
			print(
				"Location tracking leaked, started: \(stackSize), ended: \(locationStack.locations.count)")
		}

		return SourceLocation(
			path: start.path,
			start: start,
			end: previousBeforeNewline ?? previous
		)
	}
}

extension Set<Token.Kind> {
	static let assignments: Set<Token.Kind> = [
		.equals,
		.plusEquals,
		.minusEquals,
	]
}
