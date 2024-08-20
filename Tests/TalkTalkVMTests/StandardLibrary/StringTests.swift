//
//  StringTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import TalkTalkBytecode
import TalkTalkVM
import Testing

struct StringTests: StandardLibraryTest {
	@Test("Can have a static string") func basic() async throws {
		let result = try await run("""
		return "hello world"
		""").get()

		#expect(result == .string("hello world"))
	}

	@Test("string concat") func concat() async throws {
		let result = try await run("""
		var a = "hello " + "world"
		return a
		""").get()

		#expect(result == .string("hello world"))
	}
}
