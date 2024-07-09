//
//  Parser+Rules.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//

extension Parser {
	mutating func call(_: Bool, _: any Expr) -> some Expr {
		ErrorSyntax(token: current)
	}

	mutating func unary(_: Bool) -> any Expr {
		let op = consume(current, as: UnaryOperator.self)!

		let expr = parse(precedence: .unary)
		advance()

		return UnaryExprSyntax(
			position: op.position,
			length: op.position - current.start,
			op: op,
			rhs: expr
		)
	}

	mutating func binary(_: Bool, _ lhs: any Expr) -> any Expr {
		guard let op = consume(current, as: BinaryOperatorSyntax.self) else {
			return ErrorSyntax(token: current)
		}

		let rhs = parse(precedence: current.kind.rule.precedence + 1)

		return BinaryExprSyntax(
			lhs: lhs,
			op: op,
			rhs: rhs,
			position: lhs.position,
			length: lhs.position - current.start + current.length
		)
	}

	mutating func grouping(_: Bool) -> some Expr {
		let position = current.start
		let expr = parse(precedence: .none)
		return GroupingSyntax(position: position, length: position - current.start, expression: expr)
	}

	mutating func dot(_: Bool, _: any Expr) -> some Expr {
		ErrorSyntax(token: current)
	}

	mutating func and(_: Bool, _: any Expr) -> some Expr {
		ErrorSyntax(token: current)
	}

	mutating func or(_: Bool, _: any Expr) -> some Expr {
		ErrorSyntax(token: current)
	}

	mutating func variable(_: Bool) -> some Expr {
		ErrorSyntax(token: current)
	}

	mutating func string(_: Bool) -> some Expr {
		StringLiteralSyntax(position: current.start, length: current.length, lexeme: current.lexeme(in: lexer))
	}

	mutating func number(_: Bool) -> some Expr {
		defer {
			advance()
		}

		return IntLiteralSyntax(position: current.start, length: current.length, lexeme: current.lexeme(in: lexer))
	}

	mutating func literal(_: Bool) -> some Expr {
		ErrorSyntax(token: current)
	}

	mutating func _super(_: Bool) -> some Expr {
		ErrorSyntax(token: current)
	}

	mutating func _self(_: Bool) -> some Expr {
		ErrorSyntax(token: current)
	}

	mutating func arrayLiteral(_: Bool) -> some Expr {
		ErrorSyntax(token: current)
	}
}
