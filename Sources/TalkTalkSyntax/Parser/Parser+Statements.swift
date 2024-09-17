//
//  Parser+Statements.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

extension Parser {
	mutating func ifStmt() -> any Stmt {
		let ifToken = previous.unsafelyUnwrapped
		let i = startLocation(at: ifToken)
		let condition = expr()
		let consequence = blockStmt(false)

		var elseToken: Token?
		var alternative: (any BlockStmt)?
		if let token = match(.else) {
			elseToken = token
			alternative = blockStmt(false)
		}

		return IfStmtSyntax(
			id: nextID(),
			ifToken: ifToken,
			condition: condition,
			consequence: consequence,
			elseToken: elseToken,
			alternative: alternative,
			location: endLocation(i),
			children: [condition, consequence, alternative].compactMap { $0 }
		)
	}

	mutating func forStmt() -> any Stmt {
		let forToken = previous!
		let i = startLocation(at: forToken)

		guard let element = consume(.identifier) else {
			return error(at: current, expected(.identifier))
		}

		guard let inToken = consume(.in) else {
			return error(at: current, expected(.in))
		}

		let sequence = expr()

		let body = blockStmt(false)

		return ForStmtSyntax(
			element: VarExprSyntax(id: nextID(), token: element, location: [element]),
			sequence: sequence,
			body: body,
			forToken: forToken,
			inToken: inToken,
			id: nextID(),
			location: endLocation(i)
		)
	}

	mutating func whileStmt() -> any Stmt {
		let whileToken = previous.unsafelyUnwrapped
		let i = startLocation(at: whileToken)

		skip(.newline)

		let condition = parse(precedence: .assignment)
		let body = blockStmt(false)

		return WhileStmtSyntax(id: nextID(), whileToken: whileToken, condition: condition, body: body, location: endLocation(i))
	}

	mutating func importStmt() -> any Stmt {
		let importToken = previous.unsafelyUnwrapped
		let i = startLocation(at: importToken)

		guard let name = consume(.identifier) else {
			return error(
				at: current,
				.unexpectedToken(expected: .identifier, got: current),
				expectation: .moduleName
			)
		}

		let module = IdentifierExprSyntax(id: nextID(), name: name.lexeme, location: [name])
		return ImportStmtSyntax(id: nextID(), token: importToken, module: module, location: endLocation(i))
	}

	mutating func matchStmt() -> any Stmt {
		let matchToken = previous.unsafelyUnwrapped
		let i = startLocation(at: matchToken)
		let target = expr()

		skip(.newline)
		consume(.leftBrace)
		skip(.newline)

		var cases: [CaseStmt] = []
		while !check(.eof), !check(.rightBrace) {
			skip(.newline)
			let stmt = caseStmt()
			skip(.newline)
			if let stmt = stmt as? CaseStmt {
				cases.append(stmt)
			} else {
				return error(at: current, .syntaxError("Expected case statement, got \(stmt)"), expectation: .none)
			}
		}

		skip(.newline)
		consume(.rightBrace)
		skip(.newline)

		return MatchStatementSyntax(matchToken: matchToken, target: target, cases: cases, id: nextID(), location: endLocation(i))
	}

	mutating func caseStmt() -> any Stmt {
		guard let token = consume(.case, .else) else {
			return error(at: current, .unexpectedToken(expected: .case, got: current), expectation: .none)
		}

		let i = startLocation(at: token)

		let pattern: (any Expr)? = if token.kind != .else {
			expr()
		} else {
			nil
		}

		consume(.colon)

		var stmts: [any Stmt] = []
		while !check(.case, .else), !check(.rightBrace), !check(.eof) {
			skip(.newline)
			stmts.append(stmt())
			skip(.newline)
		}

		return CaseStmtSyntax(
			caseToken: token,
			patternSyntax: pattern,
			body: stmts,
			isDefault: token.kind == .else,
			id: nextID(),
			location: endLocation(i)
		)
	}
}
