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

	mutating func dot(_ canAssign: Bool, _ lhs: any Expr) -> any Expr {
		consume(.dot, "Expected .")

		guard let identifier = consume(IdentifierSyntax.self) else {
			return ErrorSyntax(
				token: current,
				expected: .token(.identifier),
				message: "Expected identifer"
			)
		}

		if canAssign, match(.equal) {
			let rhs = expression()
			return AssignmentExpr(
				position: lhs.position,
				length: current.start - lhs.position,
				lhs: PropertyAccessExpr(
					position: lhs.position,
					length: current.start - lhs.position,
					receiver: lhs,
					property: identifier
				),
				rhs: rhs
			)
		} else if match(.leftParen) {
			let arguments = argumentList(terminator: .rightParen)

			return CallExprSyntax(
				position: lhs.position,
				length: current.start - identifier.position,
				callee: PropertyAccessExpr(
					position: lhs.position,
					length: current.start - lhs.position,
					receiver: lhs,
					property: identifier
				),
				arguments: arguments
			)
		} else {
			return PropertyAccessExpr(
				position: lhs.position,
				length: current.start - lhs.position,
				receiver: lhs,
				property: identifier
			)
		}
	}

	mutating func and(_: Bool, _ lhs: any Expr) -> some Expr {
		let op = consume(BinaryOperatorSyntax.self)!
		let rhs = expression()
		return BinaryExprSyntax(
			lhs: lhs,
			op: op,
			rhs: rhs,
			position: lhs.position,
			length: current.start - lhs.position
		)
	}

	mutating func or(_: Bool, _ lhs: any Expr) -> some Expr {
		let op = consume(BinaryOperatorSyntax.self)!
		let rhs = expression()
		return BinaryExprSyntax(
			lhs: lhs,
			op: op,
			rhs: rhs,
			position: lhs.position,
			length: current.start - lhs.position
		)
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

	mutating func literal(_: Bool) -> any Expr {
		return consume(LiteralExprSyntax.self) ??
			ErrorSyntax(token: current, expected: .type(LiteralExprSyntax.self), message: "Unreachable?")
	}

	mutating func _super(_: Bool) -> some Expr {
		defer {
			advance()
		}

		return VariableExprSyntax(
			position: previous.start,
			length: 5,
			name: .init(position: previous.start, length: 4, lexeme: "super")
		)
	}

	mutating func _self(_: Bool) -> some Expr {
		defer {
			advance()
		}

		return VariableExprSyntax(
			position: previous.start,
			length: 4,
			name: .init(position: previous.start, length: 4, lexeme: "self")
		)
	}

	mutating func arrayLiteral(_: Bool) -> some Expr {
		let start = current.start
		consume(.leftBracket, "Expected '[' to start array")
		let elements = argumentList(terminator: .rightBracket)

		return ArrayLiteralSyntax(
			position: start,
			length: current.start - start,
			elements: elements
		)
	}
}
