//
//  ArrayTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import Testing

@MainActor
struct ArrayTests: StandardLibraryTest {
	@Test("Can be created") func create() async throws {
		let result = try await run("""
		let a = Array()
		return a.count
		""").get()

		#expect(result == .int(0))
	}

	@Test("append increments count") func append() async throws {
		let source = """
		var a = []
		a.append(123)
		return a.count
		"""

		let result = try await run(source, verbosity: .verbose).get()

		#expect(result == .int(1))
	}

	@Test("can get items at index") func get() async throws {
		let source = """
		var a = []
		a.append(123)
		a.append(456)
		return a.get(1)
		"""
		let result = try await run(source).get()

		#expect(result == .int(456))
	}

	@Test("can add more than 4 items") func resizingTest() async throws {
		let source = """
		 var a = []
		 a.append(123)
		 a.append(234)
		 a.append(345)
		 a.append(456)
		 a.append(567)
		 a.append(678)
		 return a[5]
		"""
		let result = try await run(source).get()

		#expect(result == .int(678))
	}

	@Test("can create array literal") func arrayLiteral() async throws {
		let result = try await run("""
		var a = [1,2,3,4,5,6]
		return a[5]
		""").get()

		#expect(result == .int(6))
	}

	@Test("can create array literal") func arraySubscript() async throws {
		let source = """
		var a = [1,2,3,4,5,6]
		return a[5]
		"""

		let result = try await run(source).get()

		#expect(result == .int(6))
	}

	@Test("can set array value with subscript") func arraySubscriptSet() async throws {
		let source = """
		var a = [1,2,3,4,5,6]
			a[0] = 123
			return a[0]
		"""
		let result = try await run(source).get()

		#expect(result == .int(123))
	}

	@Test("Can iterate over array") func arrayIteration() async throws {
		let result = try await run("""
		var result = 0
		let a = [1,2,3]
		var i = 0
		while i < a.count {
			result = a[i]
			i = i + 1
		}
		return result
		""").get()

		#expect(result == .int(3))
	}

	@Test("something is up") func somethingIsUp() async throws {
		let source = """
		var a = [200, 300, 404]
		a.test()
		return a[3]
		"""

		let result = try await run(source).get()
		#expect(result == .int(404))
	}
}
