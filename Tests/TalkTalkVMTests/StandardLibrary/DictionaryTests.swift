//
//  DictionaryTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/22/24.
//

import TalkTalkBytecode
import Testing

@MainActor
struct DictionaryTests: StandardLibraryTest {
	@Test("Temporary hash builtin functions") func hash() async throws {
		let result = try await run("return _hash(123)").get()
		#expect(result == Value.int(.init(Value.int(123).hashValue)))
	}

	@Test("Can get a value") func basic() async throws {
		let result = try await run("""
		let a = ["foo": "bar"]
		return a["foo"]
		""").get()

		#expect(result == .string("bar"))
	}
}
