//
//  DictionaryVMTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/22/24.
//

import TalkTalkBytecode
import Testing

@MainActor
struct DictionaryVMTests: StandardLibraryTest {
	@Test("Temporary hash builtin functions") func hash() async throws {
		let result = try await run("return _hash(123)").get()
		#expect(result == Value.int(.init(Value.int(123).hashValue)))
	}

	@Test("Can get a value") func basic() async throws {
		let source = """
		var a = ["foo": "bar"]
		return a["foo"]
		"""

		let result = try await run(source).get()

		#expect(result == .string("bar"))
	}

	@Test("Returns nil when the value isn't there") func notThere() async throws {
		let source = """
		var a = ["foo": "bar"]
		return a["fizz"]
		"""

		let result = try await run(source).get()

		#expect(result == .nil)
	}

	@Test("Handles resizing") func resizing() async throws {
		let source = #"""
		var a = ["1": 1]

		var i = 2
		while i < 10 {
			a["\(i)"] = i
			i += 1
		}

		return a["9"]
		"""#

		let result = try await run(source).get()

		#expect(result == .int(9))
	}
}
