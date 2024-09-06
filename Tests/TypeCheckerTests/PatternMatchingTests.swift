//
//  PatternMatchingTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/5/24.
//

import TalkTalkSyntax
import Testing
@testable import TypeChecker

struct PatternMatchingTests: TypeCheckerTest {
	@Test("Can typecheck literal pattern") func pattern() throws {
		let syntax = try Parser.parse(
			"""
			match foo {
			case 123:
				false
			case "bar":
				true
			}
			"""
		)

		let context = try infer(syntax)
		let case1 = syntax[0].cast(MatchStatementSyntax.self).cases[0].options[0]
		let case2 = syntax[0].cast(MatchStatementSyntax.self).cases[1].options[0]

		#expect(
			context[case1] == .type(.base(.int))
		)

		#expect(
			context[case2] == .type(.base(.string))
		)
	}

	@Test("Can typecheck a match") func matchin() throws {
		let syntax = try Parser.parse(
			"""
			enum Thing {
				case foo(String)
				case bar(int)
			}

			match Thing.foo("sup") {
			case .foo(let a):
				a
			case .bar(let b):
				b
			}
			"""
		)

		let context = try infer(syntax)
		let call1 = syntax[1].cast(MatchStatementSyntax.self)
			.cases[0] // .foo(let a)...:
			.options[0] // .foo(let a)
			.cast(CallExprSyntax.self)

		let call2 = syntax[1].cast(MatchStatementSyntax.self)
			.cases[1] // .bar(let b)...:
			.options[0] // .bar(let b)
			.cast(CallExprSyntax.self)

		let foo = context.lookup(syntax: call1)
		#expect(foo == .pattern(
			.enumCase(
				EnumCase(typeName: "Thing", name: "foo", attachedTypes: [.base(.string)])
			),
			[.base(.string)]
		))

		let bar = context.lookup(syntax: call2)
		#expect(bar == .pattern(
			.enumCase(
				EnumCase(typeName: "Thing", name: "bar", attachedTypes: [.base(.int)])
			),
			[.base(.int)]
		))

		let body = syntax[1].cast(MatchStatementSyntax.self)
			.cases[0].body[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(VarExprSyntax.self)

		#expect(body.name == "a")
		#expect(context[body] == .type(.base(.string)))
	}

	@Test("Can infer nested enum patterns") func nestedEnumCases() throws {
		let syntax = try Parser.parse(
			"""
			enum Top {
				case top(String)
			}

			enum Bottom {
				case bottom(Top)
			}

			match Bottom.bottom(.top("fizz")) {
			case .bottom(.top(let a)):
				a
			}
			"""
		)

		let context = try infer(syntax)
		let call1 = syntax[2].cast(MatchStatementSyntax.self)
			.cases[0] // .foo(let a)...:
			.options[0] // .foo(let a)

		// Let's just make sure we're testing the right thing
		#expect(call1.description == ".bottom(.top(let a))")

		#expect(context.errors.isEmpty)

		let actual = context.lookup(syntax: call1)!
		let expected = InferenceType.pattern(
			.enumCase(
				EnumCase(
					typeName: "Bottom",
					name: "bottom",
					attachedTypes: [
						.enumType(.init(name: "Top", cases: [.init(typeName: "Top", name: "top", attachedTypes: [.base(.string)])]))
					]
				)
			),
			[
				.pattern(
					.enumCase(
						EnumCase(typeName: "Top", name: "top", attachedTypes: [.base(.string)])
					),
					[
						.base(.string)
					]
				)
			]
		)

		#expect(actual == expected)
	}
}
