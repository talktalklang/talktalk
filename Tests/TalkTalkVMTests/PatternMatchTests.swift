//
//  PatternMatchTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/10/24.
//

import Testing

struct PatternMatchTests: VMTest {
	@Test("Basic") func basic() throws {
		let result = try run(
			"""
			match true {
			case false:
				return 123
			case true:
				return 456
			}
			"""
		)

		#expect(result == .int(456))
	}

	@Test("With binding") func withBinding() throws {
		let result = try run(
			"""
			enum Thing {
			case foo(int)
			case bar(int)
			}

			match Thing.bar(456) {
			case .foo(let a):
				return a
			case .bar(let b):
				return b + 1
			}
			"""
			, verbosity: .verbose)

		#expect(result == .int(457))
	}

	@Test("With values") func withValues() throws {
		let result = try run(
			"""
			enum Thing {
			case foo(int)
			case bar(int)
			}

			match Thing.foo(456) {
			case .foo(123):
				return "nope 123"
			case .bar(let a):
				return "nope bar"
			case .foo(456):
				return "yup"
			}
			"""
			, verbosity: .verbose)

		#expect(result == .string("yup"))
	}

	@Test("Matching variable") func matchingVariable() throws {
		let result = try run(
			"""
			enum Thing {
			case foo(int)
			case bar(int)
			}

			let variable = Thing.foo(456) 

			match variable {
			case .foo(123):
				return "nope 123"
			case .bar(let a):
				return "nope bar"
			case .foo(456):
				return "yup"
			}
			"""
			, verbosity: .verbose)

		#expect(result == .string("yup"))
	}
}
