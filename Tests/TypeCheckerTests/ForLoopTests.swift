//
//  ForLoopTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/17/24.
//

import TalkTalkCore
import Testing
@testable import TypeChecker

@MainActor
struct ForLoopTests: TypeCheckerTest {
	@Test("Can typecheck a for loop") func basic() throws {
		let syntax = try Parser.parse(
			"""
			for iamthevalue in [1,2,3] {
				print(iamthevalue)
			}
			"""
		)

		let context = try solve(syntax, verbose: true, debugStdlib: true)
		let forLoop = syntax[0]
		#expect(context.find(forLoop) == .void)

		let i = forLoop
			.cast(ForStmtSyntax.self).body.stmts[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(CallExprSyntax.self).args[0]

		#expect(context.find(i) == .base(.int))
	}

	@Test("Errors when sequence isn't iterable") func notIterable() throws {
		let syntax = try Parser.parse(
			"""
			for i in false {
				print(i)
			}
			"""
		)

		_ = try solve(syntax, expectedDiagnostics: 1) // Expect a conformance error and could not determine Element
	}
}
