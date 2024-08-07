//
//  Parser+Satments.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

extension Parser {
	mutating func importStmt() -> any Syntax {
		let importToken = previous!
		let i = startLocation(at: importToken)

		guard let name = consume(.identifier) else {
			return error(at: current, "Expected module name", expectation: .moduleName)
		}

		let module = IdentifierExprSyntax(name: name.lexeme, location: [name])
		return ImportStmtSyntax(token: importToken, module: module, location: endLocation(i))
	}
}
