//
//  PatternMatchingTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/5/24.
//

import Testing
@testable import TypeChecker
import TalkTalkSyntax

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
		let case1 = syntax[0].cast(MatchStatementSyntax.self).cases[0].cases[0]
		let case2 = syntax[0].cast(MatchStatementSyntax.self).cases[1].cases[0]

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
			.cases[0]	// .foo(let a)
			.cast(CallExprSyntax.self)

		let foo = context.lookup(syntax: call1)
		#expect(foo == .pattern(
			Pattern(
				type: .enumCase(
					EnumType(name: "Thing", cases: [
						EnumCase(typeName: "Thing", name: "foo", attachedTypes: [.base(.string)]),
						EnumCase(typeName: "Thing", name: "bar", attachedTypes: [.base(.int)])
					]),
					EnumCase(typeName: "Thing", name: "foo", attachedTypes: [.base(.string)])
				),
				values: [.typeVar(TypeVariable("a", 69))])
			)
		)

		let body = syntax[1].cast(MatchStatementSyntax.self)
			.cases[0].body[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(VarExprSyntax.self)

		#expect(body.name == "a")
		#expect(context[body] == .type(.base(.string)))
	}
}