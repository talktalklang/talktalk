//
//  GenericsTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/26/24.
//

import TalkTalkSyntax
import Testing
@testable import TypeChecker

struct GenericsTests {
	func infer(_ expr: [any Syntax]) throws -> InferenceContext {
		let inferencer = InferenceVisitor()
		return inferencer.infer(expr).solve()
	}

	@Test("Can typecheck a generic type") func basic() throws {
		let syntax = try Parser.parse(
			"""
			struct Wrapper<Wrapped> {
				var wrapped: Wrapped

				init(wrapped: Wrapped) {
					self.wrapped = wrapped
				}
			}

			Wrapper(wrapped: 123).wrapped
			Wrapper(wrapped: "sup").wrapped
			"""
		)

		let context = try infer(syntax)
		#expect(context[syntax[1]] == .type(.base(.int)))
		#expect(context[syntax[2]] == .type(.base(.string)))
	}

	@Test("Can typecheck nested generic types") func nestedGenerics() throws {
		let syntax = try Parser.parse(
			"""
			struct Inner<InnerWrapped> {
				let base: InnerWrapped
				init(base: InnerWrapped) {
					self.base = base
				}
			}
			struct Middle<MiddleWrapped> {
				let inner: Inner<MiddleWrapped>
				init(inner: Inner<MiddleWrapped>) {
					self.inner = inner
				}
			}
			struct Wrapper<Wrapped> {
				let middle: Middle<Inner<Wrapped>>
				init(middle: Middle<Inner<Wrapped>>) {
					self.middle = middle
				}
			}

			let inner = Inner(base: 123)
			let middle = Middle(inner: inner)
			let wrapper = Wrapper(middle: middle)
			wrapper.middle.inner.base
			"""
		)

		let context = try infer(syntax)

		let result = context[syntax[6]]
		let expected = InferenceResult.type(.base(.int))

		#expect(result == expected)
	}
}
