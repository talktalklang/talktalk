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
}
