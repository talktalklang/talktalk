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
		let optional = Instance<EnumType>.extract(from: optionalType.asType(in: context))!

		#expect(optional.type.name == "Optional")
		#expect(optional.substitutions.count == 1)

		let unwrapped = syntax[2]
			.cast(MatchStatementSyntax.self).cases[0].body[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(VarExprSyntax.self)

		#expect(context[unwrapped] == .type(.base(.int)))
	}
}
