//
//  ParserRecoveryTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/22/24.
//

import TalkTalkCore
import Testing

struct ParserRecoveryTests {
	@Test("Recovers from bad decl") func badDecl() throws {
		let parsed = try Parser.parse(
			"""
			var 123
			print("hi")
			""",
			allowErrors: true
		)[1]
			.cast(ExprStmtSyntax.self).expr
			.cast(CallExprSyntax.self)

		#expect(parsed.callee.cast(VarExprSyntax.self).name == "print")
	}

	@Test("Recovers from bad stmt") func badStmt() throws {
		let parsed = try Parser.parse(
			"""
			for a

			print("hi")
			""",
			allowErrors: true
		)[1]
			.cast(ExprStmtSyntax.self).expr
			.cast(CallExprSyntax.self)

		#expect(parsed.callee.cast(VarExprSyntax.self).name == "print")
	}
}
