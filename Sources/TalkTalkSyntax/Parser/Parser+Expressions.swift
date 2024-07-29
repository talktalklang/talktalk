//
//  Parser+Rules.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

extension Parser {
	// The key to our chris pratt parser.
	mutating func parse(precedence: Precedence) -> any Expr {
		checkForInfiniteLoop()

		var lhs: (any Expr)?
		let rule = current.kind.rule

		if let prefix = rule.prefix {
			lhs = prefix(&self, precedence.canAssign)
		}

		while precedence < current.kind.rule.precedence {
			checkForInfiniteLoop()

			if let infix = current.kind.rule.infix, lhs != nil {
				lhs = infix(&self, precedence.canAssign, lhs!)
				skip(.newline)
			}
		}

		return lhs ?? ErrorExprSyntax(
			message: "Expected lhs parsing at: \(current) pos:\(current.start) prev: \(previous.lexeme)",
			location: [previous, current]
		)
	}

	mutating func grouping(_: Bool) -> any Expr {
		guard consume(.leftParen) != nil else {
			fatalError()
		}

		let expr = parse(precedence: .assignment)

		guard consume(.rightParen) != nil else {
			fatalError()
		}

		return expr
	}

	// MARK: Nonary/Unary ops

	mutating func ifExpr(_: Bool) -> any Expr {
		startLocation()

		_ = consume(.if)

		skip(.newline)

		let condition = parse(precedence: .assignment)

		skip(.newline)

		let consequence = blockExpr(false)

		skip(.newline)
		consume(.else)
		skip(.newline)

		// TODO: make else optional
		let alternative = blockExpr(false)

		return IfExprSyntax(
			condition: condition,
			consequence: consequence,
			alternative: alternative,
			location: endLocation()
		)
	}

	mutating func funcExpr() -> Expr {
		startLocation(at: previous)

		// Grab the name if there is one
		let name: Token? = match(.identifier)

		skip(.newline)

		consume(.leftParen, "expected '(' before params")

		// Parse parameter list
		let params = parameterList()

		skip(.newline)

		let body = blockExpr(false)

		return FuncExprSyntax(params: params, body: body, i: lexer.current, name: name?.lexeme, location: endLocation())
	}

	mutating func literal(_: Bool) -> any Expr {
		if didMatch(.true) {
			return LiteralExprSyntax(value: .bool(true), location: [previous])
		}

		if didMatch(.false) {
			return LiteralExprSyntax(value: .bool(false), location: [previous])
		}

		if didMatch(.int) {
			return LiteralExprSyntax(value: .int(Int(previous.lexeme)!), location: [previous])
		}

		if didMatch(.func) {
			return funcExpr()
		}

		return ErrorExprSyntax(message: "Unknown literal: \(previous as Any)", location: [previous])
	}

	mutating func whileExpr(_ canAssign: Bool) -> any Expr {
		startLocation()

		consume(.while)
		skip(.newline)

		let condition = parse(precedence: .assignment)
		let body = blockExpr(canAssign)

		return WhileExprSyntax(condition: condition, body: body, location: endLocation())
	}

	mutating func blockExpr(_: Bool) -> BlockExprSyntax {
		skip(.newline)
		startLocation()
		consume(.leftBrace, "expected '{' before block body")
		skip(.newline)

		var body: [any Expr] = []
		while !check(.eof), !check(.rightBrace) {
			body.append(expr())
			skip(.newline)
		}

		consume(.rightBrace, "expected '}' after block body")

		return BlockExprSyntax(exprs: body, location: endLocation())
	}

	mutating func variable(_ canAssign: Bool) -> any Expr {
		startLocation()

		guard let token = consume(.identifier) else {
			return ErrorExprSyntax(message: "Expected identifier for variable", location: [current])
		}

		let lhs = VarExprSyntax(token: token, location: [token])

		if check(.equals), canAssign {
			consume(.equals)
			let rhs = parse(precedence: .assignment)
			return DefExprSyntax(name: lhs.token, value: rhs, location: endLocation())
		} else if check(.equals) {
			return ErrorExprSyntax(message: "Can't assign", location: endLocation())
		}

		return lhs
	}

	// MARK: Binary ops

	mutating func call(_: Bool, _ lhs: any Expr) -> any Expr {
		startLocation()

		consume(.leftParen) // This is how we got here.

		var args: [any Expr] = []
		if !didMatch(.rightParen) {
			repeat {
				args.append(parse(precedence: .assignment))
			} while didMatch(.comma)

			consume(.rightParen, "expected ')' after arguments")
		}

		return CallExprSyntax(callee: lhs, args: args, location: endLocation())
	}

	mutating func binary(_: Bool, _ lhs: any Expr) -> any Expr {
		startLocation(at: lhs.location.start)

		let op: BinaryOperator = switch current.kind {
		case .bangEqual: .bangEqual
		case .equalEqual: .equalEqual
		case .plus: .plus
		default:
			fatalError("unreachable")
		}

		advance()
		let rhs = parse(precedence: current.kind.rule.precedence + 1)
		return BinaryExprSyntax(lhs: lhs, rhs: rhs, op: op, location: endLocation())
	}
}
