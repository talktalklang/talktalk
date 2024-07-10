//
//  Parser.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
struct ProgramNode: Syntax {
	var position = -1
	var length = -1

	var declarations: [Decl] = []
	var description: String {
		declarations.map(\.description).joined(separator: "\n")
	}
}

struct Parser {
	var errors: [Error] = []
	var lexer: Lexer
	var previous: Token
	var current: Token
	var parserRepeats: [Int: Int] = [:]

	init(lexer: Lexer) {
		self.lexer = lexer
		self.previous = self.lexer.next()
		self.current = previous
	}

	mutating func parse() -> [any Syntax] {
		var decls: [any Syntax] = []

		while current.kind != .eof {
			decls.append(decl())
		}

		return decls
	}

	mutating func decl() -> any Decl {
		if match(.var) {
			return varDecl()
		}

		if match(.func) {
			return funcDecl()
		}

		let position = current.start
		let expr = parse(precedence: .assignment)

		return ExprStmtSyntax(
			position: current.start,
			length: position - current.start,
			expr: expr
		)
	}

	mutating func varDecl() -> any Decl {
		let start = previous.start

		guard let identifier = consume(IdentifierSyntax.self) else {
			return ErrorSyntax(token: current, expected: .identifier)
		}

		var expr: (any Expr)?
		if match(.equal) {
			expr = parse(precedence: .assignment)
		}

		return VarDeclSyntax(
			position: start,
			length: current.start - start,
			variable: identifier,
			expr: expr
		)
	}

	mutating func funcDecl() -> FunctionDeclSyntax {
		let position = previous.start
		let name = consume(IdentifierSyntax.self)!

		consume(.leftParen, "Expected '(' before parameter list")
		let parameters = parameterList()

		let body = functionBody()

		return FunctionDeclSyntax(
			position: position,
			length: current.start - position,
			name: name,
			parameters: parameters,
			body: body
		)
	}

	mutating func parse(precedence: Precedence) -> any Expr {
		checkForInfiniteLoop()

		var lhs: (any Expr)?
		let rule = current.kind.rule

		if let prefix = rule.prefix {
			lhs = prefix(&self, precedence.canAssign)
		}

		if let lhs, let infix = current.kind.rule.infix {
			return infix(&self, precedence.canAssign, lhs)
		}

		return lhs ?? ErrorSyntax(token: current)
	}

	private mutating func parameterList() -> ParameterListSyntax {
		if match(.rightParen) {
			return ParameterListSyntax(
				position: previous.start,
				length: 0,
				parameters: []
			)
		}

		let start = current.start
		var parameters: [IdentifierSyntax] = []

		repeat {
			guard let identifier = consume(IdentifierSyntax.self) else {
				break
			}

			parameters.append(identifier)
		} while match(.comma)

		consume(.rightParen, "Expected ')' after parameter list")
		return ParameterListSyntax(
			position: start,
			length: current.start - start,
			parameters: parameters
		)
	}

	private mutating func functionBody() -> BlockSyntax {
		let start = current.start
		consume(.leftBrace, "Expected '{' before function body")

		var decls: [any Decl] = []

		while !check(.rightBrace), !check(.eof) {
			skip(.newline)
			decls.append(decl())
			skip(.newline)
		}

		consume(.rightBrace, "Expected '{' after function body")

		return BlockSyntax(
			position: start,
			length: current.start - start,
			decls: decls
		)
	}
}
