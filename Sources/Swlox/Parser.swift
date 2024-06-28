enum ParserError: Error {
	case unexpectedToken(Token),
			 unexpectedAssignment(Token)
}

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
			if matching(kinds: .var) {
				return try varDeclaration()
			}

			return try statement()
		} catch {
			synchronize()
			throw error
		}
	}

	mutating func varDeclaration() throws -> any Stmt {
		guard case let .identifier(name) = advance().kind else {
			Swlox.error("Unexpected token. Expected identifier.", token: peek())
			throw ParserError.unexpectedToken(peek())
		}

		let initializer: (any Expr)?
		if peek().kind == .equal {
			try consume(.equal, "Expected var initializer")
			initializer = try expression()
		} else {
			initializer = nil
		}

		try consume(.semicolon, "Expected statement terminator")

		return VarStmt(name: name, initializer: initializer)
	}

	mutating func statement() throws -> any Stmt {
		if matching(kinds: .print) {
			return try printStmt()
		}

		return try expressionStmt()
	}

	mutating func printStmt() throws -> any Stmt {
		let expr = try expression()
		try consume(.semicolon, "Expected ';' after expression.")
		return PrintStmt(expr: expr)
	}

	mutating func expressionStmt() throws -> any Stmt {
		let expr = try expression()
		try consume(.semicolon, "Expected ';' after expression.")
		return ExpressionStmt(expr: expr)
	}

	mutating func expression() throws -> any Expr {
		return try assignment()
	}

	mutating func assignment() throws -> any Expr {
		let expr = try equality()

		// Lets see if this is an assignment
		if matching(kinds: .equal) {
			let equals = previous()
			let value = try assignment()

			if let expr = expr as? VariableExpr {
				let name = expr.name
				return AssignExpr(name: name, value: value)
			}

			throw ParserError.unexpectedAssignment(equals)
		}

		return expr
	}

	mutating func equality() throws -> any Expr {
		var expr = try comparison()

		while matching(kinds: .bangEqual, .equalEqual) {
			let op = previous()
			let rhs = try comparison()
			expr = BinaryExpr(lhs: expr, op: op, rhs: rhs)
		}

		return expr
	}

	mutating func comparison() throws -> any Expr {
		var expr = try term()

		while matching(kinds: .greater, .greaterEqual, .less, .lessEqual) {
			let op = previous()
			let rhs = try term()
			expr = BinaryExpr(lhs: expr, op: op, rhs: rhs)
		}

		return expr
	}

	mutating func term() throws -> any Expr {
		var expr = try factor()

		while matching(kinds: .minus, .plus) {
			let op = previous()
			let rhs = try factor()
			expr = BinaryExpr(lhs: expr, op: op, rhs: rhs)
		}

		return expr
	}

	mutating func factor() throws -> any Expr {
		var expr = try unary()

		while matching(kinds: .slash, .star) {
			let op = previous()
			let rhs = try unary()
			expr = BinaryExpr(lhs: expr, op: op, rhs: rhs)
		}

		return expr
	}

	mutating func unary() throws -> any Expr {
		var expr = try primary()

		while matching(kinds: .bang, .minus) {
			let op = previous()
			expr = UnaryExpr(op: op, expr: expr)
		}

		return expr
	}

	// It all comes down to this.
	mutating func primary() throws -> any Expr {
		let token = advance()

		switch token.kind {
		case .number(_), .string(_), .true, .false, .nil:
			return LiteralExpr(literal: token)
		case .identifier(_):
			return VariableExpr(name: token)
		case .leftParen:
			let expr = try expression()
			try consume(.rightParen, "Expected ')' after expression")

			return GroupingExpr(expr: expr)
		default:
			// TODO: This is wrong
			Swlox.error("Unexpected token: \(token)", token: token)

			return LiteralExpr(literal: token)
		}
	}

	private mutating func `consume`(_ kind: Token.Kind, _: String) throws {
		if isAtEnd, kind != .eof {
			Swlox.error("Unexpected end of input. Expected: \(kind)", token: previous())
			throw ParserError.unexpectedToken(previous())
		}

		if check(kind: kind) {
			advance()
			return
		}

		let token = peek()
		Swlox.error("Unexpected token: \(token), expected: \(kind)", token: token)
		throw ParserError.unexpectedToken(token)
	}

	// For error recovery
	private mutating func synchronize() {
		advance()

		while !isAtEnd {
			if previous().kind == .semicolon { return }

			switch peek().kind {
			case .class, .fun, .var, .for, .if, .while, .print, .return:
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
}
