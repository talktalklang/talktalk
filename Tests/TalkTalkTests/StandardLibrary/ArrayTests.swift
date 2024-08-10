//
//  ArrayTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import Testing

struct ArrayTests: StandardLibraryTest {
	@Test("Can be created") func create() async throws {
		let result = try await run("""
		a = Array()
		a.count
		""").get()

		#expect(result == .int(0))
	}

	@Test("Can add items") func add() async throws {
		let result = try await run("""
		a = Array()
		a.append(123)
		a.count
		""").get()

		#expect(result == .int(1))
	}
}
