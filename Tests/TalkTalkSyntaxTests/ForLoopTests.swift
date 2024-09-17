//
//  ForLoopTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/17/24.
//

import TalkTalkSyntax
import Testing

struct ForLoopTests {
	@Test("Can lex a for loop") func lexin() throws {
		let tokens = Lexer.collect(
		"""
		for i in a { }
		"""
		)

		#expect(tokens.map(\.kind) == [
			.for,
			.identifier,
			.in,
			.identifier,
			.leftBrace,
			.rightBrace,
			.eof
		])
	}

	@Test("Can parse a for loop") func parsin() throws {
		let parsed = try Parser.parse(
			"""
			for i in a {
				print(i)
			}
			"""
		)[0].cast(ForStmtSyntax.self)

		#expect(parsed.element.cast(VarExprSyntax.self).name == "i")
		#expect(parsed.sequence.cast(VarExprSyntax.self).name == "a")
		#expect(parsed.body.stmts.count == 1)

		let bodyStmt = parsed.body.stmts[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(CallExprSyntax.self)

		#expect(bodyStmt.callee.cast(VarExprSyntax.self).name == "print")
		#expect(bodyStmt.args.count == 1)
		#expect(bodyStmt.args[0].value.cast(VarExprSyntax.self).name == "i")
	}
}
