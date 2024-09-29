//
//  OptionalsTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/17/24.
//
import TalkTalkCore
import Testing
@testable import TypeChecker

struct OptionalsTest: TypeCheckerTest {
	@Test("Can infer optional") func basic() throws {
		let syntax = try Parser.parse(
			"""
			var foo: int?

			foo

			match foo {
			case .some(let val):
				val
			case .none:
				123
			}
			"""
		)

		let context = try infer(syntax)
		let optionalType = context[syntax[1]]!
		#expect(optionalType == .type(.optional(.base(.int))))

		let unwrapped = syntax[2]
			.cast(MatchStatementSyntax.self).cases[0].body[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(VarExprSyntax.self)

		#expect(context[unwrapped] == .type(.base(.int)))
	}

	@Test("Returning value") func returningValue() throws {
		let syntax = try Parser.parse(
			"""
			func maybe(on: bool) -> int? {
				if on {
					return 123
				} else {
					return none
				}
			}

			maybe(true)
			"""
		)

		let context = try infer(syntax)
		let optionalType = context[syntax[1]]!
	}

	@Test("Returning none") func returningNone() throws {

	}
}
