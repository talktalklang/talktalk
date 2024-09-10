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
				return b
			}
			"""
		)

		#expect(result == .int(456))
	}
}
