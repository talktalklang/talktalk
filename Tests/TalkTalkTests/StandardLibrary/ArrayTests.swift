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
		return a.count
		""").get()

		#expect(result == .int(0))
	}

	@Test("append increments count") func append() async throws {
		let result = try await run("""
		a = Array()
		a.append(123)
		return a.count
		""", verbose: true).get()

		#expect(result == .int(1))
	}

	@Test("can get items at index") func get() async throws {
		let result = try await run("""
		a = Array()
		a.append(123)
		a.at(0)
		""").get()

		#expect(result == .int(123))
	}
}
