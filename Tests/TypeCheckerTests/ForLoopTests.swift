//
//  ForLoopTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/17/24.
//

import TalkTalkSyntax
import Testing
@testable import TypeChecker

@MainActor
struct ForLoopTests: TypeCheckerTest {
	@Test("Can typecheck a for loop") func basic() throws {
		let syntax = try Parser.parse(
			"""
			for i in [1,2,3] {
				print(i)
			}
			"""
		)

		let context = try infer(syntax)
		let forLoop = syntax[0]
		try #expect(context.get(forLoop) == .type(.void))

		let i = forLoop
			.cast(ForStmtSyntax.self).body.stmts[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(CallExprSyntax.self).args[0]

		#expect(context[i] == .type(.base(.int)))
	}

	@Test("Errors when sequence isn't iterable") func notIterable() throws {
		let syntax = try Parser.parse(
			"""
			for i in false {
				print(i)
			}
			"""
		)

		_ = try infer(syntax, expectedErrors: 2) // Expect a conformance error and could not determine Element
	}
}
