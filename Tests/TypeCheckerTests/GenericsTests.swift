//
//  GenericsTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/26/24.
//

import TalkTalkCore
import Testing
@testable import TypeChecker

@MainActor
struct GenericsTests: TypeCheckerTest {
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

		let context = try solve(syntax)

		#expect(context[syntax[1]] == .base(.int))
		#expect(context[syntax[2]] == .base(.string))
	}

	@Test("Can infer from synthesized init") func synthesizedInit() throws {
		let syntax = try Parser.parse(
			"""
			struct Wrapper<Wrapped> {
				var wrapped: Wrapped
			}

			Wrapper(wrapped: 123).wrapped
			Wrapper(wrapped: "sup").wrapped
			"""
		)

		let context = try solve(syntax)
		#expect(context[syntax[1]] == .base(.int))
		#expect(context[syntax[2]] == .base(.string))
	}

	@Test("Can typecheck type param members", .disabled("still need to figure out semantics here")) func typeParamMember() throws {
		let syntax = try Parser.parse(
			"""
			struct Wrapper<Wrapped> {
				var wrapped: Wrapped
			}

			Wrapper<int>.Wrapped
			"""
		)

		let context = try infer(syntax)
		let result1 = context[syntax[1]]
		#expect(result1 == .type(.base(.int)))
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

			struct Wrapper<Wrapped> {
				let inner: Inner<Wrapped>
				init(inner: Inner<Wrapped>) {
					self.inner = inner
				}
			}

			let inner = Inner(base: 123)
			let wrapper = Wrapper(inner: inner)
			wrapper.inner.base
			"""
		)

		let context = try solve(syntax, verbose: true)
		#expect(context[syntax[4]] == .base(.int))
	}

	@Test("Can typecheck very nested generic types") func veryNestedGenerics() throws {
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

		let context = try solve(syntax)
		#expect(context[syntax[6]] == .base(.int))
	}
}
