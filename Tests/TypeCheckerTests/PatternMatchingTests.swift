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
		let case1 = syntax[0].cast(MatchStatementSyntax.self).cases[0].patternSyntax!
		let case2 = syntax[0].cast(MatchStatementSyntax.self).cases[1].patternSyntax!

		#expect(
			context[case1] == .type(.base(.int))
		)

		#expect(
			context[case2] == .type(.base(.string))
		)
	}

	@Test("Can typecheck with else") func patternElse() throws {
		let syntax = try Parser.parse(
			"""
			match thing {
			case 123:
				true
			else:
				false
			}
			"""
		)

		let context = try infer(syntax)
		#expect(context.errors == [])

		let case1 = syntax[0].cast(MatchStatementSyntax.self).cases[0].patternSyntax!
		let case2 = syntax[0].cast(MatchStatementSyntax.self).cases[1].patternSyntax

		#expect(
			context[case1] == .type(.base(.int))
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

			let m = Thing.foo("sup")

			match m {
			case .foo(let a):
				a
			case .bar(let b):
				b
			}
			"""
		)

		let context = try infer(syntax)
		let call1 = syntax[2].cast(MatchStatementSyntax.self)
			.cases[0] // .foo(let a)...:
			.patternSyntax! // .foo(let a)
			.cast(CallExprSyntax.self)

		let call2 = syntax[2].cast(MatchStatementSyntax.self)
			.cases[1] // .bar(let b)...:
			.patternSyntax! // .bar(let b)
			.cast(CallExprSyntax.self)

		let enumType = try EnumType.extract(from: context.get(syntax[0]))!

		let foo = context.lookup(syntax: call1)
		#expect(foo == .pattern(Pattern(
			type: .enumCase(
				EnumCase(type: enumType, name: "foo", index: 0, attachedTypes: [.base(.string)])
			),
			arguments: [.variable("a", .base(.string))]
		)))

		let bar = context.lookup(syntax: call2)
		#expect(bar == .pattern(Pattern(
			type: .enumCase(
				EnumCase(type: enumType, name: "bar", index: 1, attachedTypes: [.base(.int)])
			),
			arguments: [.variable("b", .base(.int))]
		)))

		let body = syntax[2].cast(MatchStatementSyntax.self)
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
		let call1 = syntax[2].cast(MatchStatementSyntax.self).cases[0].patternSyntax!

		let topType = try EnumType.extract(from: context.get(syntax[0]))!
		let bottomType = try EnumType.extract(from: context.get(syntax[1]))!

		// Let's just make sure we're testing the right thing
		#expect(call1.description == ".bottom(.top(let a))")
		#expect(context.errors.isEmpty)

		let actual = context.lookup(syntax: call1)!
		let expected = InferenceType.pattern(Pattern(
			type: .enumCase(
				EnumCase(
					type: bottomType,
					name: "bottom",
					index: 0,
					attachedTypes: [
						.instantiatable(
							EnumType(
								name: "Top",
								cases: topType.cases,
								context: topType.context,
								typeContext: .init(name: "Bottom")
							)
						),
					]
				)
			),
			arguments: [
				.value(
					.pattern(
						Pattern(
							type: .enumCase(
								EnumCase(type: topType, name: "top", index: 0, attachedTypes: [.base(.string)])
							),
							arguments: [.variable("a", .base(.string))]
						)
					)
				),
			]
		))

		#expect(actual == expected)
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

		let context = try infer(syntax)
		#expect(context.errors == [])

		let kaseArg = syntax[3]
			.cast(MatchStatementSyntax.self).cases[1]
			.cast(CaseStmtSyntax.self).patternSyntax!
			.cast(CallExprSyntax.self).args[1].value

		let match = try context.get(kaseArg)
		let kase = try #require(EnumCase.extract(from: match))

		#expect(kase.type.name == "B")
		#expect(kase.name == "fizz")
	}
}
