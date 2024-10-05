//
//  PatternMatchingTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/5/24.
//

import TalkTalkCore
import Testing
@testable import TypeChecker

struct PatternMatchingTests: TypeCheckerTest {
	@Test("Can typecheck literal pattern") func pattern() throws {
		let syntax = try Parser.parse(
			"""
			let foo = ""
			match foo {
			case 123:
				false
			case "bar":
				true
			}
			"""
		)

		let context = try solve(syntax)
		let case1 = syntax[1].cast(MatchStatementSyntax.self).cases[0].patternSyntax!
		let case2 = syntax[1].cast(MatchStatementSyntax.self).cases[1].patternSyntax!

		#expect(
			context.find(case1) == .pattern(.value(.base(.int)))
		)

		#expect(
			context.find(case2) == .pattern(.value(.base(.string)))
		)
	}

	@Test("Can typecheck with else") func patternElse() throws {
		let syntax = try Parser.parse(
			"""
			match 345 {
			case 123:
				true
			else:
				false
			}
			"""
		)

		let context = try solve(syntax)

		let case1 = syntax[0].cast(MatchStatementSyntax.self).cases[0].patternSyntax!
		let case2 = syntax[0].cast(MatchStatementSyntax.self).cases[1].patternSyntax

		#expect(
			context.find(case1) == .pattern(.value(.base(.int)))
		)

		#expect(
			case2 == nil
		)
	}

	@Test("Can typecheck a match") func matchin() throws {
		let syntax = try Parser.parse(
			"""
			enum Thing {
				case foo(String)
				case bar(int)
			}

			func m() -> Thing {
				Thing.foo("sup")	
			}
			

			match m() {
			case .foo(let a):
				a
			case .bar(let a):
				a
			}
			"""
		)

		let context = try solve(syntax)
		let call1 = syntax[2].cast(MatchStatementSyntax.self)
			.cases[0] // .foo(let a)...:
			.patternSyntax! // .foo(let a)
			.cast(CallExprSyntax.self)

		let call2 = syntax[2].cast(MatchStatementSyntax.self)
			.cases[1] // .bar(let b)...:
			.patternSyntax! // .bar(let b)
			.cast(CallExprSyntax.self)

		let enumType = Enum.extract(from: context.find(syntax[0])!)!
		let fooCase = enumType.cases["foo"]!
		let barCase = enumType.cases["bar"]!

		let foo = context.find(call1)
		#expect(foo == .pattern(
			.call(
				.type(
					.type(
						.enumCase(fooCase)
					)
				),
				[.variable("a", .type(.base(.string)))])
		))

		let body = syntax[2].cast(MatchStatementSyntax.self)
			.cases[0].body[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(VarExprSyntax.self)

		#expect(body.name == "a")
		#expect(context.find(body) == .base(.string))

		let bar = context.find(call2)
		#expect(bar == .pattern(
			.call(
				.type(
					.type(
						.enumCase(barCase)
					)
				),
				[.variable("a", .type(.base(.int)))])
		))

		let body2 = syntax[2].cast(MatchStatementSyntax.self)
			.cases[0].body[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(VarExprSyntax.self)

		#expect(body2.name == "a")
		#expect(context.find(body2) == .base(.string))
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

			func m() -> Bottom {
				Bottom.bottom(.top("fizz"))
			}

			match m() {
			case .bottom(.top(let a)):
				a
			}
			"""
		)

		let context = try solve(syntax)
		let call1 = syntax[3].cast(MatchStatementSyntax.self).cases[0].patternSyntax!

		let topType = Enum.extract(from: context.find(syntax[0])!)!
		let bottomType = Enum.extract(from: context.find(syntax[1])!)!
		let bottomCase = bottomType.cases["bottom"]!
		let topCase = topType.cases["top"]!

		// Let's just make sure we're testing the right thing
		#expect(call1.description == ".bottom(.top(let a))")
		#expect(context.find(call1) == .pattern(
			.call(
				.type(.type(.enumCase(bottomCase))),
				[
					.call(
						.type(.type(.enumCase(topCase))),
						[.variable("a", .type(.base(.string)))]
					)
				]
			)
		))
	}

	@Test("Can infer out of order nested") func outOfOrderNested() throws {
		let syntax = try Parser.parse(
			"""
			enum A {
				case foo(int, B)
				case bar(int, B)
			}

			enum B {
				case fizz(int)
				case buzz(int)
			}

			let variable = A.foo(10, .fizz(20)) 

			match variable {
			case .bar(let a, .fizz(let b)):
				return 29 // Nope
			case .foo(let a, .fizz(let b)):
				return a + b
			}
			"""
		)

		_ = try solve(syntax)
	}
}
