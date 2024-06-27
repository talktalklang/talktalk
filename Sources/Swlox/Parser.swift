// “expression     → equality ;
// equality       → comparison ( ( "!=" | "==" ) comparison )* ;
// comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
// term           → factor ( ( "-" | "+" ) factor )* ;
// factor         → unary ( ( "/" | "*" ) unary )* ;
// unary          → ( "!" | "-" ) unary
//                | primary ;
// primary        → NUMBER | STRING | "true" | "false" | "nil"
//                | "(" expression ")" ;”

struct Parser {
	var current = 0
	var tokens: [Token]

	init(tokens: [Token]) {
		self.tokens = tokens
	}

	mutating func expression() -> some Expr {
		return equality()
	}

	mutating func equality() -> some Expr {
		var expr = comparison()

		while matching(kinds: .bangEqual, .equalEqual) {
			let op = previous()
			let rhs = comparison()
			expr = BinaryExpr(lhs: expr, op: op, rhs: rhs)
		}

		return expr
	}

	func comparison() -> some Expr {

	}

	mutating private func matching(kinds: Token.Kind...) -> Bool {
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

	@discardableResult mutating private func advance() -> Token {
		if !isAtEnd { current += 1 }
		return previous()
	}

	private var isAtEnd: Bool {
		peek().kind == .eof
	}

	private func peek() -> Token {
		tokens[current]
	}

	private func previous() -> Token {
		tokens[current-1]
	}

}
