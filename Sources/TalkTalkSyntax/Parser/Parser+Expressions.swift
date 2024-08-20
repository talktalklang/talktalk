//
//  Parser+Expressions.swift
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

		if check(.newline), let lhs {
			return lhs
		}

		while precedence < current.kind.rule.precedence {
			checkForInfiniteLoop()

			if previous.kind == .newline {
				break
			}

			if let infix = current.kind.rule.infix, lhs != nil {
				lhs = infix(&self, precedence.canAssign, lhs!)

				if check(.newline) {
					break
				}
			}
		}

		return lhs ?? ParseErrorSyntax(
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
			return error(at: current, .unexpectedToken(expected: .rightParen, got: current), expectation: .none)
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
			return error(at: current, .unexpectedToken(expected: .if, got: current), expectation: .none)
		}

		skip(.newline)

		let condition = parse(precedence: .assignment)

		skip(.newline)

		let consequence = blockStmt(false)

		skip(.newline)
		let elseToken = consume(.else)
		skip(.newline)

		// TODO: make else optional
		let alternative = blockStmt(false)

		return IfExprSyntax(
			ifToken: ifToken,
			elseToken: elseToken,
			condition: condition,
			consequence: consequence,
			alternative: alternative,
			location: endLocation(i)
		)
	}

	mutating func funcExpr() -> any Expr {
		let funcToken = previous!
		let i = startLocation(at: previous)

		// Grab the name if there is one
		let name: Token? = match(.identifier)

		skip(.newline)

		consume(.leftParen, "expected '(' before params")

		// Parse parameter list
		let params = parameterList()

		skip(.newline)

		let body = blockStmt(false)

		let funcExpr = FuncExprSyntax(
			funcToken: funcToken,
			params: params,
			body: body,
			i: lexer.current,
			name: name,
			location: endLocation(i)
		)

		if check(.leftParen) {
			return call(false, funcExpr)
		}

		return funcExpr
	}

	mutating func arrayLiteral(_: Bool) -> any ArrayLiteralExpr {
		let i = startLocation()
		_ = consume(.leftBracket)
		var exprs: [any Expr] = []

		repeat {
			skip(.newline)
			if check(.rightBracket) {
				// If we get a comma right before a right bracket, it's just a trailing comma
				// and we can bail out of the loop.
				break
			}
			skip(.newline)
			exprs.append(parse(precedence: .assignment))
			skip(.newline)
		} while didMatch(.comma)

		consume(.rightBracket, "expected ']' after array literal")

		return ArrayLiteralExprSyntax(exprs: exprs, location: endLocation(i))
	}

	mutating func literal(_: Bool) -> any Expr {
		if didMatch(.true) {
			return LiteralExprSyntax(value: .bool(true), location: [previous])
		}

		if didMatch(.false) {
			return LiteralExprSyntax(value: .bool(false), location: [previous])
		}

		if didMatch(.string) {
			let string = previous.lexeme.split(separator: "")[1 ..< previous.lexeme.count - 1].joined(separator: "")
			return LiteralExprSyntax(value: .string(string), location: [previous])
		}

		if didMatch(.int), let int = Int(previous.lexeme) {

			return LiteralExprSyntax(value: .int(int), location: [previous])
		}

		if didMatch(.func) {
			return funcExpr()
		}

		return ParseErrorSyntax(location: [previous], message: "Unknown literal: \(previous as Any)", expectation: .none)
	}

	mutating func returning(_: Bool) -> any Stmt {
		let i = startLocation(at: previous)

		let returnToken = previous!
		let value = parse(precedence: .none)

		return ReturnStmtSyntax(returnToken: returnToken, location: endLocation(i), value: value)
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

	mutating func blockStmt(_: Bool) -> BlockStmtSyntax {
		let i = startLocation()
		skip(.newline)
		consume(.leftBrace, "expected '{' before block body")
		skip(.newline)

		var body: [any Stmt] = []
		while !check(.eof), !check(.rightBrace) {
			body.append(stmt())
			skip(.newline)
		}

		consume(.rightBrace, "expected '}' after block body")

		return BlockStmtSyntax(stmts: body, location: endLocation(i))
	}

	mutating func variable(_ canAssign: Bool) -> any Expr {
		let i = startLocation()

		guard let token = consume(.identifier) else {
			return ParseErrorSyntax(location: [current], message: "Expected identifier for variable", expectation: .variable)
		}

		let lhs = VarExprSyntax(token: token, location: endLocation(i))

		if check(.equals), canAssign {
			let i = startLocation(at: lhs.token)
			consume(.equals)
			let rhs = parse(precedence: .assignment)
			return DefExprSyntax(receiver: lhs, value: rhs, location: endLocation(i))
		} else if check(.equals) {
			return ParseErrorSyntax(location: endLocation(i), message: "Can't assign", expectation: .none)
		}

		// this is sorta weird but we're gonna go with it for now.
		// check to see if the next token is < and if it follows the identifier immediately
		// if there's no space, treat it as a type parameter list opener.
		if check(.less), lhs.location.start.end == peek().start {
			let i = startLocation(at: lhs.token)
			consume(.less)
			skip(.newline)
			let genericParams = genericParams()
			skip(.newline)
			return TypeExprSyntax(identifier: lhs.token, genericParams: genericParams, location: endLocation(i))
		}

		return lhs
	}

	// MARK: Binary ops

	mutating func call(_: Bool, _ lhs: any Expr) -> any Expr {
		let i = startLocation(at: lhs.location.start)

		consume(.leftParen) // This is how we got here.

		var args: [CallArgument] = []
		if !didMatch(.rightParen) {
			args = argumentList()
		}

		return CallExprSyntax(callee: lhs, args: args, location: endLocation(i))
	}

	mutating func subscriptCall(_ canAssign: Bool, _ lhs: any Expr) -> any Expr {
		let i = startLocation(at: lhs.location.start)
		consume(.leftBracket)

		let args = argumentList(terminator: .rightBracket)

		if didMatch(.equals), canAssign {
			let assignee = SubscriptExprSyntax(receiver: lhs, args: args, location: endLocation(i))
			let value = parse(precedence: .assignment)
			return DefExprSyntax(receiver: assignee, value: value, location: [assignee.location.start, value.location.end])
		} else if didMatch(.equals) {
			return error(at: current, .cannotAssign, expectation: .none)
		} else {
			return SubscriptExprSyntax(receiver: lhs, args: args, location: endLocation(i))
		}
	}

	mutating func dot(_ canAssign: Bool, _ lhs: any Expr) -> any Expr {
		let i = startLocation(at: previous)
		consume(.dot)

		guard let member = consume(.identifier, "expected identifier for property access") else {
			_ = error(
				at: current,
				.unexpectedToken(expected: .identifier, got: current),
				expectation: .member
			)
			return MemberExprSyntax(
				receiver: lhs,
				property: "",
				propertyToken: .synthetic(.identifier),
				location: endLocation(i)
			)
		}

		if check(.equals), canAssign {
			consume(.equals)
			let rhs = parse(precedence: .assignment)
			let member = MemberExprSyntax(
				receiver: lhs,
				property: member.lexeme,
				propertyToken: member,
				location: [member]
			)
			return DefExprSyntax(receiver: member, value: rhs, location: endLocation(i))
		} else if check(.equals) {
			return ParseErrorSyntax(location: endLocation(i), message: "Can't assign", expectation: .none)
		}

		return MemberExprSyntax(
			receiver: lhs,
			property: member.lexeme,
			propertyToken: member,
			location: endLocation(i)
		)
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
		case .is: .is
		default:
			fatalError("unreachable")
		}

		advance()
		let rhs = if op == .is {
			typeExpr()
		} else {
			parse(precedence: current.kind.rule.precedence + 1)
		}
		return BinaryExprSyntax(lhs: lhs, rhs: rhs, op: op, location: endLocation(i))
	}

	mutating func typeExpr() -> TypeExpr {
		let typeID = consume(.identifier)
		let i = startLocation(at: previous!)

		var genericParamsSyntax: GenericParamsSyntax? = nil
		if didMatch(.less) {
			genericParamsSyntax = genericParams()
		}

		var errors: [String] = []

		if typeID == nil {
			errors.append("Expected identifier")
		}

		return TypeExprSyntax(
			identifier: typeID ?? .synthetic(.error),
			genericParams: genericParamsSyntax,
			location: endLocation(i),
			errors: errors
		)
	}
}
