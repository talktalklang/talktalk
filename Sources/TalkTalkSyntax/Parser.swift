//
//  Parser.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct ProgramSyntax: Syntax {
	public let start: Token
	public let end: Token

	public var decls: [any Decl] = []

	public var description: String {
		decls.map(\.description).joined(separator: "\n")
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: inout Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: &context)
	}
}

struct Parser {
	var errors: [Error] = []
	var lexer: Lexer
	var previous: Token
	var current: Token
	var parserRepeats: [Int: Int] = [:]
	var declContext: DeclContext = .topLevel

	init(lexer: Lexer) {
		self.lexer = lexer
		self.previous = self.lexer.next()
		self.current = previous
	}

	init(copying: inout Parser, declContext: DeclContext) {
		self.lexer = copying.lexer
		self.previous = copying.previous
		self.current = copying.current
		self.declContext = declContext
	}

	mutating func withDeclContext<D: Decl>(
		_ context: DeclContext,
		perform: (inout Parser) -> D
	) -> D {
		let currentContext = declContext
		var copy = Parser(copying: &self, declContext: context)

		defer {
			self = Parser(copying: &copy, declContext: currentContext)
		}

		return perform(&copy)
	}

	mutating func parse() -> [any Decl] {
		var decls: [any Decl] = []

		skip(.statementTerminators)

		while current.kind != .eof {
			decls.append(decl())
			skip(.statementTerminators)
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

		if match(.class) {
			return classDecl()
		}

		if match(.`init`) {
			return initDecl()
		}

		return statement()
	}

	mutating func varDecl() -> any Decl {
		guard declContext.allowedDecls.contains(.var) else {
			return ErrorSyntax(
				token: current,
				expected: .none,
				message: "Cannot define vars from \(declContext)"
			)
		}

		let start = previous

		guard let identifier = consume(IdentifierSyntax.self) else {
			return ErrorSyntax(
				token: current,
				expected: .token(.identifier),
				message: "Expected identifier in var declaration"
			)
		}

		let typeDecl: TypeDeclSyntax? = if match(.colon) {
			{ () -> TypeDeclSyntax? in
				guard let name = consume(IdentifierSyntax.self) else {
					return nil
				}

				return TypeDeclSyntax(
					start: start,
					end: previous,
					name: name
				)
			}()
		} else {
			nil
		}

		var expr: (any Expr)?
		if match(.equal) {
			expr = parse(precedence: .assignment)
		}

		return VarDeclSyntax(
			start: start,
			end: previous,
			variable: identifier,
			typeDecl: typeDecl,
			expr: expr
		)
	}

	mutating func funcDecl() -> any Decl {
		guard declContext.allowedDecls.contains(.func) else {
			return ErrorSyntax(
				token: previous,
				expected: .none,
				message: "Cannot define func from \(declContext)"
			)
		}

		let start = previous
		let name = consume(IdentifierSyntax.self)!

		consume(.leftParen, "Expected '(' before parameter list")
		let parameters = parameterList()

		var typeDecl: TypeDeclSyntax? = nil
		let typeDeclStart = current
		if match(.rightArrow), let name = consume(IdentifierSyntax.self) {
			typeDecl = TypeDeclSyntax(
				start: typeDeclStart,
				end: previous,
				name: name
			)
		}

		let body = withDeclContext(.function) { $0.block() }

		return FunctionDeclSyntax(
			start: start,
			end: previous,
			name: name,
			parameters: parameters,
			typeDecl: typeDecl,
			body: body
		)
	}

	mutating func initDecl() -> any Decl {
		guard declContext.allowedDecls.contains(.`init`) else {
			return ErrorSyntax(
				token: previous,
				expected: .none,
				message: "Cannot define init from \(declContext)"
			)
		}

		let start = previous

		consume(.leftParen, "Expected '(' before parameter list")
		let parameters = parameterList()

		let body = withDeclContext(.`init`) {
			$0.block()
		}

		return InitDeclSyntax(
			start: start,
			end: previous,
			parameters: parameters,
			body: body
		)
	}

	mutating func classDecl() -> any Decl {
//		guard declContext.allowedDecls.contains(.class) else {
//			return ErrorSyntax(
//				token: current,
//				expected: .none,
//				message: "Cannot define class from \(declContext)"
//			)
//		}

		let start = previous

		guard let name = consume(IdentifierSyntax.self) else {
			return ErrorSyntax(
				token: current,
				expected: .token(.identifier),
				message: "Expected class name"
			)
		}

		let body = withDeclContext(.class) { $0.block() }
		return ClassDeclSyntax(
			start: start,
			end: previous,
			name: name,
			body: body
		)
	}

	mutating func statement() -> any Stmt {
		if match(.leftBrace) {
			return block()
		}

		if match(.if) {
			return ifStatement()
		}

		if match(.while) {
			return whileStatement()
		}

		if match(.return) {
			return returnStatement()
		}

		let start = current
		let expr = parse(precedence: .assignment)

		return ExprStmtSyntax(
			start: start,
			end: previous,
			expr: expr
		)
	}

	mutating func expression() -> any Expr {
		parse(precedence: .assignment)
	}

	mutating func parse(precedence: Precedence) -> any Expr {
		checkForInfiniteLoop()

		var lhs: (any Expr)?
		let rule = current.kind.rule

		if let prefix = rule.prefix {
			lhs = prefix(&self, precedence.canAssign)
		}

		while precedence < current.kind.rule.precedence {
			if let infix = current.kind.rule.infix, lhs != nil {
				lhs = infix(&self, precedence.canAssign, lhs!)
				skip(.statementTerminators)
			}
		}

		if lhs == nil {}

		return lhs ?? ErrorSyntax(
			token: current,
			expected: .type(ExprStmtSyntax.self),
			message: "Expected lhs parsing"
		)
	}

	private mutating func parameterList() -> ParameterListSyntax {
		let start = previous

		if match(.rightParen) {
			return ParameterListSyntax(
				start: start,
				end: previous,
				parameters: []
			)
		}

		var parameters: [IdentifierSyntax] = []

		repeat {
			guard let identifier = consume(IdentifierSyntax.self) else {
				break
			}

			parameters.append(identifier)
		} while match(.comma)

		consume(.rightParen, "Expected ')' after parameter list")
		return ParameterListSyntax(
			start: start,
			end: previous,
			parameters: parameters
		)
	}

	private mutating func block() -> BlockStmtSyntax {
		let start = current

		skip(.newline) // for brace on next line style that i don't love
		consume(.leftBrace, "Expected '{' before function body")
		skip(.newline)

		var decls: [any Decl] = []

		while !check(.rightBrace), !check(.eof) {
			skip(.newline)
			decls.append(decl())
			skip(.statementTerminators)
		}

		consume(.rightBrace, "Expected '{' after function body")

		return BlockStmtSyntax(
			start: start,
			end: previous,
			decls: decls
		)
	}

	mutating func argumentList(terminator: Token.Kind) -> ArgumentListSyntax {
		let start = current
		var arguments: [any Expr] = []

		if !match(terminator) {
			repeat {
				arguments.append(parse(precedence: .assignment))
			} while match(.comma) && !match(.eof)

			consume(terminator, "Expected ')' after argument list")
		}

		return ArgumentListSyntax(
			start: start,
			end: previous,
			arguments: arguments
		)
	}

	mutating func ifStatement() -> IfStmtSyntax {
		let start = previous

		let condition = parse(precedence: .assignment)
		let body = block()

		return IfStmtSyntax(
			start: start,
			end: previous,
			condition: condition,
			body: body
		)
	}

	mutating func whileStatement() -> WhileStmtSyntax {
		let start = previous

		let condition = parse(precedence: .assignment)
		let body = block()

		return WhileStmtSyntax(
			start: start,
			end: previous,
			condition: condition,
			body: body
		)
	}

	mutating func returnStatement() -> ReturnStmtSyntax {
		let start = previous
		let value = parse(precedence: .assignment)
		return ReturnStmtSyntax(
			start: start,
			end: previous,
			value: value
		)
	}
}
