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

		let result = try await run(source, verbosity: .verbose).get()

		#expect(result == .string("bar"))
	}
}
