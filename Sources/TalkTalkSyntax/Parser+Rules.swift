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
				expected: .type(BinaryOperatorSyntax.self),
				message: "Expected binary operator"
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
		ErrorSyntax(
			token: current,
			expected: .token(.dot),
			message: "FIXME"
		)
	}

	mutating func and(_: Bool, _: any Expr) -> some Expr {
		ErrorSyntax(token: current, expected: .token(.andAnd), message: "FIXME")
	}

	mutating func or(_: Bool, _: any Expr) -> some Expr {
		ErrorSyntax(token: current, expected: .token(.pipePipe), message: "FIXME")
	}

	mutating func variable(_ canAssign: Bool) -> any Expr {
		let start = current.start
		let lhs: any Expr

		if let identifier = consume(IdentifierSyntax.self) {
			lhs = VariableExprSyntax(
				position: identifier.position,
				length: identifier.length,
				name: identifier
			)
		} else {
			lhs = ErrorSyntax(
				token: current,
				expected: .token(.identifier),
				message: "Expected identifier for variable name"
			)
		}

		if canAssign, match(.equal) {
			let rhs = parse(precedence: .assignment)
			return AssignmentExpr(
				position: start,
				length: current.start - start,
				lhs: lhs,
				rhs: rhs
			)
		}

		return lhs
	}

	mutating func string(_: Bool) -> any Expr {
		if let expr = consume(StringLiteralSyntax.self) {
			return expr
		} else {
			return ErrorSyntax(
				token: current,
				expected: .token(.string),
				message: "Expected string literal"
			)
		}
	}

	mutating func number(_: Bool) -> any Expr {
		if let expr = consume(IntLiteralSyntax.self) {
			return expr
		} else {
			return ErrorSyntax(
				token: current,
				expected: .token(.number),
				message: "Expected int literal"
			)
		}
	}

	mutating func literal(_: Bool) -> some Expr {
		ErrorSyntax(token: current, expected: .token(.dot), message: "FIXME")
	}

	mutating func _super(_: Bool) -> some Expr {
		ErrorSyntax(token: current, expected: .token(.dot), message: "FIXME")
	}

	mutating func _self(_: Bool) -> some Expr {
		ErrorSyntax(token: current, expected: .token(.dot), message: "FIXME")
	}

	mutating func arrayLiteral(_: Bool) -> some Expr {
		ErrorSyntax(token: current, expected: .token(.dot), message: "FIXME")
	}
}
