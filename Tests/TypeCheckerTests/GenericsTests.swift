//
//  GenericsTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/26/24.
//

import Testing
import TalkTalkSyntax
@testable import TypeChecker

struct GenericsTests {
	func infer(_ expr: [any Syntax]) throws -> InferenceContext {
		let inferencer = InferenceVisitor()
		return inferencer.infer(expr)
	}

	@Test("Can typecheck a generic type") func basic() throws {
		let syntax = try Parser.parse(
			"""
			struct Wrapper<Wrapped> {
				var wrapped: Wrapped
			}

			Wrapper(wrapped: 123).wrapped
			Wrapper(wrapped: "sup").wrapped
			"""
		)

		let context = try infer(syntax)
		#expect(context[syntax[1]] == .type(.base(.int)))
		#expect(context[syntax[2]] == .type(.base(.string)))
	}
}
