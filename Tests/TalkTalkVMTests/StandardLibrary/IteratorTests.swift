//
//  IteratorTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/17/24.
//

import Testing

@MainActor
struct IteratorTests: StandardLibraryTest {
	@Test("Can iterate over arrays") func create() async throws {
		let output = TestOutput()
		_ = try await run(
			#"""
			let a = ["a", "b", "c"]
			for i in a {
				print("!! \(i)")
			}
			"""#,
			output: output
		).get()

		#expect(output.stdout == """
		!! a
		!! b
		!! c

		""")
	}

	@Test("Can iterate over ints") func ints() async throws {
		let output = TestOutput()
		_ = try await run(
			#"""
			for i in [1, 2, 3] {
				print(i)
			}
			"""#,
			output: output
		).get()

		#expect(output.stdout == """
		1
		2
		3

		""")
	}
}
