// “expression     → equality ;
// equality       → comparison ( ( "!=" | "==" ) comparison )* ;
// comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
// term           → factor ( ( "-" | "+" ) factor )* ;
// factor         → unary ( ( "/" | "*" ) unary )* ;
// unary          → ( "!" | "-" ) unary
//                | primary ;
// primary        → NUMBER | STRING | "true" | "false" | "nil"
//                | "(" expression ")" ;”

enum ParserError: Error {
	case unexpectedToken(Token)
}

struct Parser {
	var current = 0
	var tokens: [Token]

	init(tokens: [Token]) {
		self.tokens = tokens
	}

	mutating func expression() throws -> any Expr {
		return try equality()
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

	mutating func primary() throws -> any Expr {
		// primary        → NUMBER | STRING | "true" | "false" | "nil"
		//                | "(" expression ")" ;”
		let token = advance()

		switch token.kind {
		case .number(_), .string(_), .true, .false, .nil:
			return LiteralExpr(literal: token)
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
		if check(kind: kind) {
			advance()
			return
		}

		let token = peek()
		Swlox.error("Unexpected token: \(token)", token: token)

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
		peek().kind == .eof
	}

	private func peek() -> Token {
		tokens[current]
	}

	private func previous() -> Token {
		tokens[current - 1]
	}
}
