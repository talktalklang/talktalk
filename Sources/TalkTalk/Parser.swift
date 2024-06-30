enum ParserError: Error {
	case unexpectedToken(Token),
	     unexpectedAssignment(Token)
}

// The parser.... parses. It is where precedence and associtivity happens.
struct Parser {
	var current = 0
	var tokens: [Token]

	init(tokens: [Token]) {
		self.tokens = tokens
	}

	mutating func parse() throws -> [any Stmt] {
		var statements: [any Stmt] = []

		while !isAtEnd {
			if let stmt = try declaration() {
				statements.append(stmt)
			}
		}

		return statements
	}

	mutating func declaration() throws -> (any Stmt)? {
		do {
			if matching(kinds: .func) {
				return try function("func")
			}

			if matching(kinds: .var) {
				return try varDeclaration()
			}

			if matching(kinds: .class) {
				return try classDeclaration()
			}

			return try statement()
		} catch {
			synchronize()
			throw error
		}
	}

	mutating func classDeclaration() throws -> any Stmt {
		let (name, _) = try consumeIdentifier()
		try consume(.leftBrace, "Expected '{' before class body")

		var methods: [FunctionStmt] = []
		while !check(kind: .rightBrace), !isAtEnd {
			try consume(.func, "Expected `func` for method definition")
			let method = try function("method")
			methods.append(method)
		}

		try consume(.rightBrace, "Expected '}' after class body")

		return ClassStmt(name: name, methods: methods)
	}

	mutating func varDeclaration() throws -> any Stmt {
		let (token, _) = try consumeIdentifier()

		let initializer: (any Expr)?
		if peek().kind == .equal {
			try consume(.equal, "Expected var initializer")
			initializer = try expression()
		} else {
			initializer = nil
		}

		try consume(.semicolon, "Expected statement terminator")

		return VarStmt(name: token, initializer: initializer)
	}

	mutating func statement() throws -> any Stmt {
		if matching(kinds: .if) {
			return try ifStmt()
		}

		if matching(kinds: .print) {
			return try printStmt()
		}

		if matching(kinds: .return) {
			return try returnStmt()
		}

		if matching(kinds: .while) {
			return try whileStmt()
		}

		if matching(kinds: .leftBrace) {
			return try BlockStmt(statements: block())
		}

		return try expressionStmt()
	}

	mutating func ifStmt() throws -> any Stmt {
		let condition = try expression()
		let thenStatement = try statement()

		if matching(kinds: .else) {
			let elseStatement = try statement()
			return IfStmt(condition: condition, thenStatement: thenStatement, elseStatement: elseStatement)
		}

		return IfStmt(condition: condition, thenStatement: thenStatement, elseStatement: nil)
	}

	mutating func whileStmt() throws -> any Stmt {
		let condition = try expression()
		try consume(.leftBrace, "Expected '{' to start while loop")
		let statements = try block()

		return WhileStmt(condition: condition, body: statements)
	}

	mutating func printStmt() throws -> any Stmt {
		let expr = try expression()
		try consume(.semicolon, "Expected ';' after expression.")
		return PrintStmt(expr: expr)
	}

	mutating func returnStmt() throws -> any Stmt {
		let token = previous()
		var value: (any Expr)?

		if !check(kind: .semicolon) {
			value = try expression()
		}

		try consume(.semicolon, "Expected semicolon after return, got: \(previous())")

		return ReturnStmt(token: token, value: value)
	}

	mutating func expressionStmt() throws -> any Stmt {
		let expr = try expression()
		try consume(.semicolon, "Expected ';' after expression.")
		return ExpressionStmt(expr: expr)
	}

	mutating func block() throws -> [any Stmt] {
		var statements: [any Stmt] = []

		while !check(kind: .rightBrace), !isAtEnd {
			if let decl = try declaration() {
				statements.append(decl)
			}
		}

		try consume(.rightBrace, "Expected '}' after block")

		return statements
	}

	mutating func function(_ kind: String) throws -> FunctionStmt {
		let (nameToken, _) = try consumeIdentifier()

		try consume(.leftParen, "Expected '(' after \(kind) name)")

		var parameters: [Token] = []

		if !check(kind: .rightParen) {
			repeat {
				if parameters.count >= 255 {
					TalkTalk.error("Can't have more than 255 params, cmon", token: peek())
				}

				let (token, _) = try consumeIdentifier()
				parameters.append(token)
			} while matching(kinds: .comma)
		}

		try consume(.rightParen, "Expected ')' after parameters")
		try consume(.leftBrace, "Expected '{' before \(kind) body")

		return try FunctionStmt(id: "_func_\(nextID())", name: nameToken, params: parameters, body: block())
	}

	mutating func expression() throws -> any Expr {
		return try assignment()
	}

	mutating func assignment() throws -> any Expr {
		let expr = try or()

		// Lets see if this is an assignment
		if matching(kinds: .equal) {
			let equals = previous()
			let value = try assignment()

			if let expr = expr as? VariableExpr {
				let name = expr.name
				return AssignExpr(id: nextID(), name: name, value: value)
			} else if let expr = expr as? GetExpr {
				return SetExpr(id: nextID(), receiver: expr.receiver, name: expr.name, value: value)
			}

			throw ParserError.unexpectedAssignment(equals)
		}

		return expr
	}

	mutating func or() throws -> any Expr {
		var expr = try and()

		while matching(kinds: .pipePipe) {
			let op = previous()
			let rhs = try and()
			expr = LogicExpr(id: nextID(), lhs: expr, op: op, rhs: rhs)
		}

		return expr
	}

	mutating func and() throws -> any Expr {
		var expr = try equality()

		while matching(kinds: .andAnd) {
			let op = previous()
			let rhs = try equality()
			expr = LogicExpr(id: nextID(), lhs: expr, op: op, rhs: rhs)
		}

		return expr
	}

	mutating func equality() throws -> any Expr {
		var expr = try comparison()

		while matching(kinds: .bangEqual, .equalEqual) {
			let op = previous()
			let rhs = try comparison()
			expr = BinaryExpr(id: nextID(), lhs: expr, op: op, rhs: rhs)
		}

		return expr
	}

	mutating func comparison() throws -> any Expr {
		var expr = try term()

		while matching(kinds: .greater, .greaterEqual, .less, .lessEqual) {
			let op = previous()
			let rhs = try term()
			expr = BinaryExpr(id: nextID(), lhs: expr, op: op, rhs: rhs)
		}

		return expr
	}

	mutating func term() throws -> any Expr {
		var expr = try factor()

		while matching(kinds: .minus, .plus) {
			let op = previous()
			let rhs = try factor()
			expr = BinaryExpr(id: nextID(), lhs: expr, op: op, rhs: rhs)
		}

		return expr
	}

	mutating func factor() throws -> any Expr {
		var expr = try unary()

		while matching(kinds: .slash, .star) {
			let op = previous()
			let rhs = try unary()
			expr = BinaryExpr(id: nextID(), lhs: expr, op: op, rhs: rhs)
		}

		return expr
	}

	mutating func unary() throws -> any Expr {
		while matching(kinds: .bang, .minus) {
			let op = previous()
			let expr = try unary()
			return UnaryExpr(id: nextID(), op: op, expr: expr)
		}

		return try call()
	}

	mutating func call() throws -> any Expr {
		var expr = try primary()

		while true {
			if matching(kinds: .leftParen) {
				expr = try finishCall(expr)
			} else if matching(kinds: .dot) {
				let (name, _) = try consumeIdentifier()
				expr = GetExpr(id: nextID(), receiver: expr, name: name)
			} else {
				break
			}
		}

		return expr
	}

	mutating func finishCall(_ callee: any Expr) throws -> any Expr {
		var arguments: [any Expr] = []

		if !check(kind: .rightParen) {
			repeat {
				try arguments.append(expression())
			} while matching(kinds: .comma)
		}

		let closingParen = try consume(.rightParen, "Expected ')' after arguments")

		return CallExpr(id: nextID(), callee: callee, closingParen: closingParen, arguments: arguments)
	}

	// It all comes down to this.
	mutating func primary() throws -> any Expr {
		let token = advance()

		switch token.kind {
		case .number(_), .string(_), .true, .false, .nil:
			return LiteralExpr(id: nextID(), literal: token)
		case .self:
			return SelfExpr(id: nextID(), token: token)
		case .identifier:
			return VariableExpr(id: nextID(), name: token)
		case .leftParen:
			let expr = try expression()
			try consume(.rightParen, "Expected ')' after expression")

			return GroupingExpr(id: nextID(), expr: expr)
		default:
			// TODO: This is wrong
			TalkTalk.error("Unexpected token: \(token)", token: token)

			return LiteralExpr(id: nextID(), literal: token)
		}
	}

	@discardableResult private mutating func `consume`(_ kind: Token.Kind, _: String) throws -> Token {
		if isAtEnd, kind != .eof {
			TalkTalk.error("Unexpected end of input. Expected: \(kind)", token: previous())
			throw ParserError.unexpectedToken(previous())
		}

		if check(kind: kind) {
			let prev = previous()
			advance()
			return prev
		}

		let token = peek()
		TalkTalk.error("Unexpected token: \(token), expected: \(kind)", token: token)
		throw ParserError.unexpectedToken(token)
	}

	private mutating func consumeIdentifier() throws -> (Token, String) {
		if isAtEnd {
			TalkTalk.error("Unexpected end of input. Expected identifier.", token: previous())
			throw ParserError.unexpectedToken(previous())
		}

		if case let .identifier(name) = peek().kind {
			let token = peek()
			advance()
			return (token, name)
		}

		let token = peek()
		TalkTalk.error("Unexpected token: \(token), expected: identifier", token: token)
		throw ParserError.unexpectedToken(token)
	}

	// For error recovery
	private mutating func synchronize() {
		advance()

		while !isAtEnd {
			if previous().kind == .semicolon { return }

			switch peek().kind {
			case .class, .func, .var, .for, .if, .while, .print, .return:
				return
			default:
				advance()
			}
		}
	}

	private mutating func matching(kinds: Token.Kind...) -> Bool {
		for kind in kinds {
			if check(kind: kind) {
				advance()
				return true
			}
		}

		return false
	}

	private func check(kind: Token.Kind) -> Bool {
		if isAtEnd { return false }
		return peek().kind == kind
	}

	@discardableResult private mutating func advance() -> Token {
		defer {
			current += 1
		}
		return tokens[current]
	}

	private var isAtEnd: Bool {
		current >= tokens.count || peek().kind == .eof
	}

	private func peek() -> Token {
		tokens[current]
	}

	private func previous() -> Token {
		tokens[current - 1]
	}

	private func nextID() -> String {
		"\(previous().id)_\(current)"
	}
}
