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
}

struct Parser {
	var errors: [Error] = []
	var lexer: Lexer
	var current: Token
	var parserRepeats: [Int: Int] = [:]

	init(lexer: Lexer) {
		self.lexer = lexer
		self.current = self.lexer.next()
	}

	mutating func parse() -> [any Syntax] {
		var decls: [any Syntax] = []

		while current.kind != .eof {
			decls.append(decl())
		}

		return decls
	}

	mutating func decl() -> any Syntax {
		switch current.kind {
		default:
			let position = current.start
			let expr = parse(precedence: .assignment)
			return ExprStmtSyntax(
				position: current.start,
				length: position - current.start,
				expr: expr
			)
		}
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
}
