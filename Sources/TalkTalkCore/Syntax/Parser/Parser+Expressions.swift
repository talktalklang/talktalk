//
//  Parser+Expressions.swift
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

		if check(.newline), let lhs {
			return lhs
		}

		while precedence < current.kind.rule.precedence {
			checkForInfiniteLoop()

			if previous.kind == .newline {
				break
			}

			if let infix = current.kind.rule.infix, let prevLHS = lhs {
				lhs = infix(&self, precedence.canAssign, prevLHS)

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
		skip(.newline)

		let i = startLocation()

		guard consume(.leftParen) != nil else {
			return error(at: current, .unexpectedToken(expected: .leftParen, got: current), expectation: .none)
		}

		skip(.newline)
		let expr = parse(precedence: .assignment)
		skip(.newline)

		guard consume(.rightParen) != nil else {
			return error(at: current, .unexpectedToken(expected: .rightParen, got: current), expectation: .none)
		}

		skip(.newline)

		return GroupedExprSyntax(expr: expr, id: nextID(), location: endLocation(i))
	}

	// MARK: Nonary/Unary ops

	mutating func unary(_: Bool) -> any Expr {
		let i = startLocation()
		advance()

		let op = previous.unsafelyUnwrapped
		let expr = parse(precedence: .unary)

		return UnaryExprSyntax(id: nextID(), op: op, expr: expr, location: endLocation(i))
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
			id: nextID(),
			ifToken: ifToken,
			elseToken: elseToken,
			condition: condition,
			consequence: consequence,
			alternative: alternative,
			location: endLocation(i)
		)
	}

	mutating func funcSignatureDecl() -> FuncSignatureDeclSyntax {
		let funcToken = previous.unsafelyUnwrapped
		let i = startLocation(at: previous)

		// Grab the name if there is one
		let name: Token = consume(.identifier) ?? .synthetic(.identifier, lexeme: "<missing>")

		skip(.newline)

		consume(.leftParen)

		// Parse parameter list
		let params = parameterList()

		skip(.newline)

		let typeDecl = if didMatch(.forwardArrow) {
			// We've got a type decl
			typeExpr()
		} else {
			{
				_ = error(at: previous, .unexpectedToken(expected: .forwardArrow, got: current), expectation: .type)
				return TypeExprSyntax(
					id: nextID(),
					identifier: .synthetic(.identifier, lexeme: "<missing>"),
					genericParams: [],
					isOptional: false,
					location: [previous]
				)
			}()
		}

		return FuncSignatureDeclSyntax(
			funcToken: funcToken,
			name: name,
			params: params,
			returnDecl: typeDecl,
			id: nextID(),
			location: endLocation(i)
		)
	}

	mutating func funcExpr(isStatic: Bool, modifiers: [Token] = []) -> any Expr {
		let funcToken = previous.unsafelyUnwrapped
		let i = startLocation(at: previous)

		// Grab the name if there is one
		let name: Token? = match(.identifier)

		skip(.newline)
		consume(.leftParen)
		skip(.newline)

		// Parse parameter list
		let params = parameterList()

		skip(.newline)

		let typeDecl: TypeExprSyntax? = if didMatch(.forwardArrow) {
			// We've got a type decl
			typeExpr()
		} else {
			nil
		}

		let body = blockStmt(false)

		let funcExpr = FuncExprSyntax(
			id: nextID(),
			modifierTokens: modifiers,
			funcToken: funcToken,
			params: params,
			typeDecl: typeDecl,
			body: body,
			isStatic: isStatic,
			name: name,
			location: endLocation(i)
		)

		if check(.leftParen) {
			return call(false, funcExpr)
		}

		return funcExpr
	}

	mutating func arrayLiteral(_ canAssign: Bool) -> any Expr {
		let i = startLocation()
		_ = consume(.leftBracket)
		var exprs: [any Expr] = []

		var isDictionary = false

		repeat {
			skip(.newline)

			if check(.rightBracket) {
				// If we get a comma right before a right bracket, it's just a trailing comma
				// and we can bail out of the loop.
				break
			}

			skip(.newline)
			let expr = parse(precedence: .assignment)
			skip(.newline)

			if didMatch(.colon) || isDictionary {
				isDictionary = true

				if exprs.isEmpty, check(.rightBracket) {
					// If the first time we encounter a colon is immediately followed by a right bracket,
					// it's an empty dictionary literal
					break
				}

				skip(.newline)
				let value = parse(precedence: .assignment)
				skip(.newline)
				exprs.append(DictionaryElementExprSyntax(id: nextID(), key: expr, value: value, location: [expr.location.start, value.location.end]))
			} else {
				exprs.append(expr)
			}
		} while didMatch(.comma)
		skip(.newline)

		consume(.rightBracket)
		skip(.newline)

		let literal: any Expr = if isDictionary {
			DictionaryLiteralExprSyntax(
				id: nextID(),
				// swiftlint:disable force_cast
				elements: exprs as! [any DictionaryElementExpr],
				// swiftlint:enable force_cast
				location: endLocation(i)
			)
		} else {
			ArrayLiteralExprSyntax(id: nextID(), exprs: exprs, location: endLocation(i))
		}

		if check(.leftBracket) {
			return subscriptCall(canAssign, literal)
		}

		return literal
	}

	mutating func literal(_: Bool) -> any Expr {
		if didMatch(.true) {
			return LiteralExprSyntax(id: nextID(), value: .bool(true), location: [previous])
		}

		if didMatch(.false) {
			return LiteralExprSyntax(id: nextID(), value: .bool(false), location: [previous])
		}

		if didMatch(.nil) {
			return LiteralExprSyntax(id: nextID(), value: .nil, location: [previous])
		}

		if didMatch(.string) {
			if previous.lexeme.count == 2 {
				// It's an empty string, no need to parse
				return LiteralExprSyntax(
					id: nextID(),
					value: .string(""),
					location: [previous]
				)
			}

			do {
				let stringParserContext: StringParser<String>.Context = check(.interpolationStart) ? .beforeInterpolation : .normal

				// swiftlint:disable force_unwrapping
				let beginString = previous!
				// swiftlint:enable force_unwrapping

				if didMatch(.interpolationStart) {
					return interpolatedString(startToken: previous, beginStringToken: beginString, interpolationStart: previous)
				}

				let value = try StringParser.parse(previous.lexeme, context: stringParserContext)
				return LiteralExprSyntax(id: nextID(), value: .string(value), location: [previous])
			} catch let error as StringParser<String>.StringError {
				return self.error(at: previous, .syntaxError(error.errorDescription))
			} catch {
				return self.error(at: previous, .syntaxError("\(error)"))
			}
		}

		if didMatch(.int), let int = Int(previous.lexeme) {
			return LiteralExprSyntax(id: nextID(), value: .int(int), location: [previous])
		}

		if didMatch(.func) {
			return funcExpr(isStatic: true, modifiers: [])
		}

		return ParseErrorSyntax(location: [previous], message: "Unknown literal: \(previous as Any)", expectation: .none)
	}

	mutating func interpolatedString(startToken: Token, beginStringToken: Token, interpolationStart: Token) -> any Expr {
		let i = startLocation(at: startToken)
		var stringParserContext: StringParser<String>.Context = .beforeInterpolation
		var segments: [InterpolatedStringSegment] = []

		do {
			let beginString = try StringParser.parse(beginStringToken.lexeme, context: stringParserContext)

			segments.append(.string(beginString, beginStringToken))

			try segments.append(
				.expr(
					interpolation(start: interpolationStart)
				)
			)

			stringParserContext = .afterInterpolation

			// Finish the string
			while check(.interpolationStart) || check(.string) {
				if check(.eof) {
					return error(at: current, .syntaxError("Unterminated string interpolation"))
				}

				if let start = match(.interpolationStart) {
					try segments.append(.expr(interpolation(start: start)))
					stringParserContext = .afterInterpolation
				} else if let string = match(.string) {
					let value = try StringParser.parse(string.lexeme, context: stringParserContext)

					segments.append(.string(value, string))
					stringParserContext = .normal
				}
			}
		} catch {
			return self.error(at: current, .syntaxError(error.localizedDescription))
		}

		return InterpolatedStringExprSyntax(segments: segments, id: nextID(), location: endLocation(i))
	}

	mutating func interpolation(start: Token) throws -> InterpolatedStringSegment.InterpolatedExpr {
		// We're in an interpolation, so we want the expression
		let interpolated = expr()

		// Make sure the interpolation ends
		guard let end = consume(.interpolationEnd) else {
			throw ParserError.couldNotParse([
				.init(line: current.line, column: current.column, kind: expected(.interpolationEnd)),
			])
		}

		return .init(expr: interpolated, startToken: start, endToken: end)
	}

	mutating func returning(_: Bool) -> any Stmt {
		let i = startLocation(at: previous)
		let returnToken = previous.unsafelyUnwrapped

		let value = parse(precedence: .none)

		return ReturnStmtSyntax(id: nextID(), returnToken: returnToken, location: endLocation(i), value: value)
	}

	mutating func structExpr(_: Bool) -> StructExpr {
		let structToken = consume(.struct).unsafelyUnwrapped
		let i = startLocation(at: previous)

		let name = match(.identifier)

		var typeParameters: [TypeExprSyntax] = []
		if didMatch(.less) {
			typeParameters = self.typeParameters()
		}

		let body = declBlock(context: .struct)

		return StructExprSyntax(
			id: nextID(),
			structToken: structToken,
			name: name?.lexeme,
			typeParameters: typeParameters,
			body: body,
			location: endLocation(i)
		)
	}

	mutating func typeParameters() -> [TypeExprSyntax] {
		var types: [TypeExprSyntax] = []
		repeat {
			skip(.newline)
			types.append(typeExpr())
			skip(.newline)
		} while didMatch(.comma)

		skip(.newline)
		consume(.greater)
		skip(.newline)

		return types
	}

	mutating func blockStmt(_: Bool) -> BlockStmtSyntax {
		let i = startLocation()
		skip(.newline)
		consume(.leftBrace)
		skip(.newline)

		var body: [any Stmt] = []
		while !check(.eof), !check(.rightBrace) {
			body.append(stmt())
			skip(.newline)
		}

		consume(.rightBrace)

		return BlockStmtSyntax(id: nextID(), stmts: body, location: endLocation(i))
	}

	mutating func variable(_ canAssign: Bool) -> any Expr {
		let i = startLocation()

		guard let token = consume(.identifier) else {
			return ParseErrorSyntax(location: [current], message: "Expected identifier for variable", expectation: .variable)
		}

		let lhs = VarExprSyntax(id: nextID(), token: token, location: endLocation(i))

		if let token = match(.assignments), canAssign {
			let i = startLocation(at: lhs.token)
			let rhs = parse(precedence: .assignment)
			return DefExprSyntax(id: nextID(), receiver: lhs, value: rhs, op: token, location: endLocation(i))
		} else if check(.assignments) {
			return ParseErrorSyntax(location: endLocation(i), message: "Can't assign", expectation: .none)
		}

		// this is sorta weird but we're gonna go with it for now.
		// check to see if the next token is < and if it follows the identifier immediately
		// if there's no space, treat it as a type parameter list opener.
		if check(.less), lhs.location.start.end == peek().start {
			let i = startLocation(at: lhs.token)
			consume(.less)
			skip(.newline)
			let genericParams = typeParameters()
			skip(.newline)
			return TypeExprSyntax(
				id: nextID(),
				identifier: lhs.token,
				genericParams: genericParams,
				isOptional: false,
				location: endLocation(i)
			)
		}

		return lhs
	}

	// MARK: Binary ops

	mutating func call(_: Bool, _ lhs: any Expr) -> any Expr {
		let i = startLocation(at: lhs.location.start)

		skip(.newline)
		consume(.leftParen) // This is how we got here.
		skip(.newline)

		var args: [Argument] = []
		if !didMatch(.rightParen) {
			args = argumentList()
		}

		return CallExprSyntax(id: nextID(), callee: lhs, args: args, location: endLocation(i))
	}

	mutating func subscriptCall(_ canAssign: Bool, _ lhs: any Expr) -> any Expr {
		let i = startLocation(at: lhs.location.start)
		consume(.leftBracket)

		let args = argumentList(terminator: .rightBracket)

		if let op = match(.assignments), canAssign {
			let assignee = SubscriptExprSyntax(id: nextID(), receiver: lhs, args: args, location: endLocation(i))
			let value = parse(precedence: .assignment)
			return DefExprSyntax(id: nextID(), receiver: assignee, value: value, op: op, location: [assignee.location.start, value.location.end])
		} else if didMatch(.equals) {
			return error(at: current, .cannotAssign, expectation: .none)
		} else {
			return SubscriptExprSyntax(id: nextID(), receiver: lhs, args: args, location: endLocation(i))
		}
	}

	mutating func dot(_: Bool) -> any Expr {
		let i = startLocation()
		consume(.dot)
		guard let property = consume(.identifier) else {
			return error(at: current, expected(.identifier), expectation: .identifier)
		}

		return MemberExprSyntax(
			id: nextID(),
			receiver: nil,
			property: property.lexeme,
			propertyToken: property,
			location: endLocation(i)
		)
	}

	mutating func member(_ canAssign: Bool, _ lhs: any Expr) -> any Expr {
		let i = startLocation(at: previous)
		consume(.dot)

		guard let member = consume(.identifier) else {
			_ = error(
				at: current,
				.unexpectedToken(expected: .identifier, got: current),
				expectation: .member
			)
			return MemberExprSyntax(
				id: nextID(),
				receiver: lhs,
				property: "",
				propertyToken: .synthetic(.identifier),
				location: endLocation(i)
			)
		}

		if let op = match(.assignments), canAssign {
			let rhs = parse(precedence: .assignment)
			let member = MemberExprSyntax(
				id: nextID(),
				receiver: lhs,
				property: member.lexeme,
				propertyToken: member,
				location: [member]
			)
			return DefExprSyntax(id: nextID(), receiver: member, value: rhs, op: op, location: endLocation(i))
		} else if check(.assignments) {
			return ParseErrorSyntax(location: endLocation(i), message: "Can't assign", expectation: .none)
		}

		return MemberExprSyntax(
			id: nextID(),
			receiver: lhs,
			property: member.lexeme,
			propertyToken: member,
			location: endLocation(i)
		)
	}

	// Convert `a += 1` to `a = a + 1` and `a -= 1` to `a = a - 1`
	mutating func incDecOp(_: Bool, _ lhs: any Expr) -> any Expr {
		let op = current
		advance()
		let i = startLocation(at: op)

		guard let lhs = lhs as? VarExprSyntax else {
			return error(at: previous, .cannotAssign, expectation: .identifier)
		}

		let add = parse(precedence: .assignment)
		let binaryExpr = if op.kind == .plusEquals {
			BinaryExprSyntax(id: nextID(), lhs: lhs, rhs: add, op: .plus, location: add.location)
		} else {
			BinaryExprSyntax(id: nextID(), lhs: lhs, rhs: add, op: .minus, location: add.location)
		}

		return DefExprSyntax(id: nextID(), receiver: lhs, value: binaryExpr, op: op, location: endLocation(i))
	}

	mutating func and(_: Bool, _ lhs: any Expr) -> any Expr {
		let i = startLocation(at: lhs.location.start)
		skip(.newline)

		advance()
		// swiftlint:disable force_unwrapping
		let op = previous!
		// swiftlint:enable force_unwrapping

		let rhs = expr()

		return LogicalExprSyntax(lhs: lhs, rhs: rhs, op: op, id: nextID(), location: endLocation(i))
	}

	mutating func or(_: Bool, _ lhs: any Expr) -> any Expr {
		let i = startLocation(at: lhs.location.start)
		skip(.newline)

		advance()
		// swiftlint:disable force_unwrapping
		let op = previous!
		// swiftlint:enable force_unwrapping

		let rhs = expr()

		return LogicalExprSyntax(lhs: lhs, rhs: rhs, op: op, id: nextID(), location: endLocation(i))
	}

	mutating func binary(_: Bool, _ lhs: any Expr) -> any Expr {
		let i = startLocation(at: lhs.location.start)

		skip(.newline)

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
		case .percent: .percent
		default:
			// swiftlint:disable fatal_error
			fatalError("unreachable")
			// swiftlint:disable fatal_error
		}

		advance()
		skip(.newline)

		let rhs: any Expr = if op == .is {
			typeExpr()
		} else {
			parse(precedence: current.kind.rule.precedence + 1)
		}

		skip(.newline)

		return BinaryExprSyntax(id: nextID(), lhs: lhs, rhs: rhs, op: op, location: endLocation(i))
	}

	mutating func typeExpr() -> TypeExprSyntax {
		let typeID = consume(.identifier)
		let i = startLocation(at: previous.unsafelyUnwrapped)
		var isOptional = didMatch(.questionMark)

		skip(.newline)
		var typeParameters: [TypeExprSyntax] = []
		if didMatch(.less) {
			skip(.newline)
			typeParameters = self.typeParameters()
			isOptional = didMatch(.questionMark)
			skip(.newline)
		}

		skip(.newline)
		var errors: [String] = []

		if typeID == nil {
			errors.append("Expected identifier")
		}

		return TypeExprSyntax(
			id: nextID(),
			identifier: typeID ?? .synthetic(.error),
			genericParams: typeParameters,
			isOptional: isOptional,
			location: endLocation(i),
			errors: errors
		)
	}

	func expected(_ kind: Token.Kind) -> SyntaxErrorKind {
		.unexpectedToken(expected: kind, got: current)
	}
}
