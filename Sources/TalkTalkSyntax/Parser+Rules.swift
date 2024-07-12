//
//  Parser+Rules.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//

extension Parser {
	mutating func call(_: Bool, _ lhs: any Expr) -> some Expr {
		let start = current

		consume(.leftParen, "Expected '(' before argument list")

		let argumentList = argumentList(terminator: .rightParen)

		return CallExprSyntax(
			start: start,
			end: previous,
			callee: lhs,
			arguments: argumentList
		)
	}

	mutating func unary(_: Bool) -> any Expr {
		let op = consume(UnaryOperator.self)!

		let expr = parse(precedence: .unary)
		advance()

		return UnaryExprSyntax(
			start: op.start,
			end: op.end,
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
			start: lhs.start,
			end: rhs.end
		)
	}

	mutating func grouping(_: Bool) -> some Expr {
		let start = current

		advance()
		let expr = parse(precedence: .none)

		consume(.rightParen, "Expected ')' after grouping")

		return GroupExpr(
			start: start,
			end: previous,
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
				start: lhs.end,
				end: rhs.end,
				lhs: PropertyAccessExpr(
					start: lhs.start,
					end: rhs.end,
					receiver: lhs,
					property: identifier
				),
				rhs: rhs
			)
		} else if match(.leftParen) {
			let arguments = argumentList(terminator: .rightParen)

			return CallExprSyntax(
				start: lhs.start,
				end: arguments.end,
				callee: PropertyAccessExpr(
					start: lhs.start,
					end: arguments.end,
					receiver: lhs,
					property: identifier
				),
				arguments: arguments
			)
		} else {
			return PropertyAccessExpr(
				start: lhs.end,
				end: identifier.start,
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
			start: lhs.start,
			end: rhs.end
		)
	}

	mutating func or(_: Bool, _ lhs: any Expr) -> some Expr {
		let op = consume(BinaryOperatorSyntax.self)!
		let rhs = expression()
		return BinaryExprSyntax(
			lhs: lhs,
			op: op,
			rhs: rhs,
			start: lhs.start,
			end: rhs.end
		)
	}

	mutating func variable(_ canAssign: Bool) -> any Expr {
		let start = current
		let lhs: any Expr

		if let identifier = consume(IdentifierSyntax.self) {
			lhs = VariableExprSyntax(
				start: start,
				end: previous,
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
				start: start,
				end: previous,
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
			start: current,
			end: current,
			name: .init(start: current, end: current, lexeme: "super")
		)
	}

	mutating func _self(_: Bool) -> some Expr {
		defer {
			advance()
		}

		return VariableExprSyntax(
			start: current,
			end: current,
			name: .init(start: current, end: current, lexeme: "self")
		)
	}

	mutating func arrayLiteral(_: Bool) -> some Expr {
		let start = current
		consume(.leftBracket, "Expected '[' to start array")
		let elements = argumentList(terminator: .rightBracket)

		return ArrayLiteralSyntax(
			start: start,
			end: previous,
			elements: elements
		)
	}
}
