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
		let result = try await run("""
		let a = [1,2,3]
		for i in a {
			print(a)
		}
		""").get()

		#expect(output.stdout == """
		1
		2
		3
		""")
	}
}
