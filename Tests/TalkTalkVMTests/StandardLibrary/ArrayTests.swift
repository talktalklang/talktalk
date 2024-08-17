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
		let a = Array()
		return a.count
		"""
		).get()

		#expect(result == .int(0))
	}

	@Test("append increments count") func append() async throws {
		let result = try await run("""
		var a = Array()
		a.append(123)
		return a.count
		""").get()

		#expect(result == .int(1))
	}

	@Test("can get items at index") func get() async throws {
		let result = try await run("""
		var a = Array()
		a.append(123)
		return a.at(0)
		""").get()

		#expect(result == .int(123))
	}

	@Test("can add more than 4 items") func subscripts() async throws {
		let result = try await run("""
		var a = Array()
		a.append(1)
		a.append(2)
		a.append(3)
		a.append(4)
		a.append(5)
		a.append(6)
		return a.at(5)
	""").get()

		#expect(result == .int(6))
	}
}
