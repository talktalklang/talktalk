//
//  StringTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import Testing
import TalkTalkVM
import TalkTalkBytecode

@MainActor
struct StringTests: StandardLibraryTest {
	@Test("Can have a static string") func basic() async throws {
		let result = try await run("""
		return "hello world"
		""").get()

		#expect(result == .string("hello world"))
	}

	@Test("Can print a static string") func printString() async throws {
		let out = try await OutputCapture.run {
			_ = try await run("""
			print("hello world")
			""")
		}

		#expect(out.stdout == "hello world\n")
	}

	@Test("Can print a dynamic string") func printDynamicString() async throws {
		let out = try await OutputCapture.run {
			_ = try await run("""
			print("hello " + "world")
			""")
		}

		#expect(out.stdout == "hello world\n")
	}

	@Test("string concat") func concat() async throws {
		let result = try await run("""
		var a = "hello " + "world"
		return a
		""").get()

		#expect(result != nil)
	}
}
