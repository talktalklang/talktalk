//
//  Parser+Rules.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//

extension Parser {
	mutating func call(_: Bool, _ lhs: any Expr) -> some Expr {
		let start = current.start

		consume(.leftParen, "Expected '(' before argument list")

		let argumentList = argumentList(terminator: .rightParen)

		consume(.rightParen, "Expected ')' after argument list")

		return CallExprSyntax(
			position: start,
			length: current.start - start,
			callee: lhs,
			arguments: argumentList
		)
	}

	mutating func unary(_: Bool) -> any Expr {
		let op = consume(UnaryOperator.self)!

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
		guard let op = consume(BinaryOperatorSyntax.self) else {
			return ErrorSyntax(
				token: current,
				expected: .type(BinaryOperatorSyntax.self)
			)
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

		advance()
		let expr = parse(precedence: .none)

		consume(.rightParen, "Expected ')' after grouping")

		return GroupExpr(
			position: position,
			length: current.start - position,
			expr: expr
		)
	}

	mutating func dot(_: Bool, _: any Expr) -> some Expr {
		ErrorSyntax(token: current, expected: .token(.dot))
	}

	mutating func and(_: Bool, _: any Expr) -> some Expr {
		ErrorSyntax(token: current, expected: .token(.andAnd))
	}

	mutating func or(_: Bool, _: any Expr) -> some Expr {
		ErrorSyntax(token: current, expected: .token(.pipePipe))
	}

	mutating func variable(_: Bool) -> any Expr {
		if let identifier = consume(IdentifierSyntax.self) {
			return VariableExprSyntax(
				position: identifier.position,
				length: identifier.length,
				name: identifier
			)
		} else {
			return ErrorSyntax(token: current, expected: .token(.identifier))
		}
	}

	mutating func string(_: Bool) -> any Expr {
		if let expr = consume(StringLiteralSyntax.self) {
			return expr
		} else {
			return ErrorSyntax(token: current, expected: .token(.string))
		}
	}

	mutating func number(_: Bool) -> any Expr {
		if let expr = consume(IntLiteralSyntax.self) {
			return expr
		} else {
			return ErrorSyntax(token: current, expected: .token(.number))
		}
	}

	mutating func literal(_: Bool) -> some Expr {
		ErrorSyntax(token: current, expected: .token(.dot))
	}

	mutating func _super(_: Bool) -> some Expr {
		ErrorSyntax(token: current, expected: .token(.dot))
	}

	mutating func _self(_: Bool) -> some Expr {
		ErrorSyntax(token: current, expected: .token(.dot))
	}

	mutating func arrayLiteral(_: Bool) -> some Expr {
		ErrorSyntax(token: current, expected: .token(.dot))
	}
}
