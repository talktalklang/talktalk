//
//  Parser+Rules.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

import Foundation

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

		return lhs ?? SyntaxError(
			location: [previous, current],
			message: "Expected lhs parsing at: \(current) pos:\(current.start) prev: \(previous.lexeme)",
			expectation: .expr
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

	mutating func unary(_: Bool) -> any Expr {
		let i = startLocation()
		advance()

		let op = previous!
		let expr = parse(precedence: .unary)

		return UnaryExprSyntax(op: op.kind, expr: expr, location: endLocation(i))
	}

	mutating func ifExpr(_: Bool) -> any Expr {
		let i = startLocation()

		guard let ifToken = consume(.if) else {
			return error(at: current, "unreachable", expectation: .none)
		}

		skip(.newline)

		let condition = parse(precedence: .assignment)

		skip(.newline)

		let consequence = blockExpr(false)

		skip(.newline)
		let elseToken = consume(.else)
		skip(.newline)

		// TODO: make else optional
		let alternative = blockExpr(false)

		return IfExprSyntax(
			ifToken: ifToken,
			elseToken: elseToken,
			condition: condition,
			consequence: consequence,
			alternative: alternative,
			location: endLocation(i)
		)
	}

	mutating func funcExpr() -> FuncExprSyntax {
		let funcToken = previous!
		let i = startLocation(at: previous)

		// Grab the name if there is one
		let name: Token? = match(.identifier)

		skip(.newline)

		consume(.leftParen, "expected '(' before params")

		// Parse parameter list
		let params = parameterList()

		skip(.newline)

		let body = blockExpr(false)

		return FuncExprSyntax(funcToken: funcToken, params: params, body: body, i: lexer.current, name: name, location: endLocation(i))
	}

	mutating func literal(_: Bool) -> any Expr {
		if didMatch(.true) {
			return LiteralExprSyntax(value: .bool(true), location: [previous])
		}

		if didMatch(.false) {
			return LiteralExprSyntax(value: .bool(false), location: [previous])
		}

		if didMatch(.string) {
			let string = previous.lexeme.split(separator: "")[1..<previous.lexeme.count-1].joined(separator: "")
			return LiteralExprSyntax(value: .string(string), location: [previous])
		}

		if didMatch(.int) {
			return LiteralExprSyntax(value: .int(Int(previous.lexeme)!), location: [previous])
		}

		if didMatch(.func) {
			return funcExpr()
		}

		return SyntaxError(location: [previous], message: "Unknown literal: \(previous as Any)", expectation: .none)
	}

	mutating func whileExpr(_ canAssign: Bool) -> any Expr {
		let i = startLocation()

		guard let whileToken = consume(.while) else {
			return error(at: current, "unreachable", expectation: .none)
		}

		skip(.newline)

		let condition = parse(precedence: .assignment)
		let body = blockExpr(canAssign)

		return WhileExprSyntax(whileToken: whileToken, condition: condition, body: body, location: endLocation(i))
	}

	mutating func returning(_ canAssign: Bool) -> any Expr {
		let i = startLocation()

		let returnToken = consume(.return)!
		let value = parse(precedence: .none)

		return ReturnExprSyntax(returnToken: returnToken, location: endLocation(i), value: value)
	}

	mutating func structExpr(_: Bool) -> StructExpr {
		let structToken = consume(.struct)!
		let i = startLocation(at: previous)

		let name = match(.identifier)

		var genericParamsSyntax: GenericParamsSyntax? = nil
		if didMatch(.less) {
			genericParamsSyntax = genericParams()
		}

		let body = declBlock()

		return StructExprSyntax(
			structToken: structToken,
			name: name?.lexeme,
			genericParams: genericParamsSyntax,
			body: body,
			location: endLocation(i)
		)
	}

	mutating func genericParams() -> GenericParamsSyntax {
		let i = startLocation(at: previous)
		let params = parameterList(terminator: .greater)
		return GenericParamsSyntax(
			params: params.params.map { GenericParamSyntax(name: $0.name) },
			location: endLocation(i)
		)
	}

	mutating func blockExpr(_: Bool) -> BlockExprSyntax {
		let i = startLocation()
		skip(.newline)
		consume(.leftBrace, "expected '{' before block body")
		skip(.newline)

		var body: [any Expr] = []
		while !check(.eof), !check(.rightBrace) {
			body.append(expr())
			skip(.newline)
		}

		consume(.rightBrace, "expected '}' after block body")

		return BlockExprSyntax(exprs: body, location: endLocation(i))
	}

	mutating func variable(_ canAssign: Bool) -> any Expr {
		let i = startLocation()

		guard let token = consume(.identifier) else {
			return SyntaxError(location: [current], message: "Expected identifier for variable", expectation: .variable)
		}

		let lhs = VarExprSyntax(token: token, location: endLocation(i))

		if check(.equals), canAssign {
			let i = startLocation(at: lhs.token)
			consume(.equals)
			let rhs = parse(precedence: .assignment)
			return DefExprSyntax(receiver: lhs, value: rhs, location: endLocation(i))
		} else if check(.equals) {
			return SyntaxError(location: endLocation(i), message: "Can't assign", expectation: .none)
		}

		return lhs
	}

	// MARK: Binary ops

	mutating func call(_: Bool, _ lhs: any Expr) -> any Expr {
		let i = startLocation()

		consume(.leftParen) // This is how we got here.

		var args: [CallArgument] = []
		if !didMatch(.rightParen) {
			repeat {
				var name: String? = nil

				if check(.identifier), checkNext(.colon) {
					let identifier = consume(.identifier)!
					consume(.colon)
					name = identifier.lexeme
				}

				let value = parse(precedence: .assignment)
				args.append(CallArgument(label: name, value: value))
			} while didMatch(.comma)

			consume(.rightParen, "expected ')' after arguments")
		}

		return CallExprSyntax(callee: lhs, args: args, location: endLocation(i))
	}

	mutating func dot(_ canAssign: Bool, _ lhs: any Expr) -> any Expr {
		let i = startLocation(at: previous)
		consume(.dot)

		guard let member = consume(.identifier, "expected identifier for property access") else {
			return error(at: current, "expected identifier for property access", expectation: .member)
		}

		if check(.equals), canAssign {
			consume(.equals)
			let rhs = parse(precedence: .assignment)
			let member = MemberExprSyntax(receiver: lhs, property: member.lexeme, location: [member])
			return DefExprSyntax(receiver: member, value: rhs, location: endLocation(i))
		} else if check(.equals) {
			return SyntaxError(location: endLocation(i), message: "Can't assign", expectation: .none)
		}

		return MemberExprSyntax(receiver: lhs, property: member.lexeme, location: endLocation(i))
	}

	mutating func binary(_: Bool, _ lhs: any Expr) -> any Expr {
		let i = startLocation(at: lhs.location.start)

		let op: BinaryOperator = switch current.kind {
		case .bangEqual: .bangEqual
		case .equalEqual: .equalEqual
		case .plus: .plus
		case .minus: .minus
		case .star: .star
		case .slash: .slash
		case .less: .less
		case .lessEqual: .lessEqual
		case .greater: .greater
		case .greaterEqual: .greaterEqual
		default:
			fatalError("unreachable")
		}

		advance()
		let rhs = parse(precedence: current.kind.rule.precedence + 1)
		return BinaryExprSyntax(lhs: lhs, rhs: rhs, op: op, location: endLocation(i))
	}
}
