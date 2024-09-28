//
//  DictionaryCompilerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/22/24.
//

import TalkTalkBytecode
import TalkTalkCompiler
import Testing

struct DictionaryCompilerTests: CompilerTest {
	@Test("Compiles dictionary") func testDictionary() async throws {
		let module = try compile("""
		[123: 456, 321: 654]
		""")

		let main = module.chunks[.function(module.name, "0.talk", [])]!
		try #expect(main.disassemble(in: module) == Instructions(
			// Emit elements onto the stack
			.op(.constant, line: 0, .constant(.int(321))),
			.op(.constant, line: 0, .constant(.int(654))),

			.op(.constant, line: 0, .constant(.int(123))),
			.op(.constant, line: 0, .constant(.int(456))),

			.op(.initDict, line: 0, .dictionary(count: 2)),
			.op(.pop, line: 0),
			.op(.returnVoid, line: 0)
		))
	}

	@Test("Compiles dictionary getter") func testDictionaryGetter() async throws {
		let module = try compile("""
			[123: 456, 321: 654][789]
			"""
		)

		let main = module.chunks[.function(module.name, "0.talk", [])]!
		try #expect(main.disassemble(in: module) == Instructions(
			// Subscript arg
			.op(.constant, line: 0, .constant(.int(789))),

			// Dict literal
			.op(.constant, line: 0, .constant(.int(321))),
			.op(.constant, line: 0, .constant(.int(654))),
			.op(.constant, line: 0, .constant(.int(123))),
			.op(.constant, line: 0, .constant(.int(456))),
			.op(.initDict, line: 0, .dictionary(count: 2)),

			// Getter
			.op(.get, line: 0, .get(.method("Standard", "Dictionary", "get", ["T"]))),
			.op(.pop, line: 0),
			.op(.returnVoid, line: 0)
		))
	}

	@Test("Compiles dictionary setter") func testDictionarySetter() async throws {
		let module = try compile("""
			var a = [123: 456, 321: 654]
			a[123] = 789
			"""
		)

		let main = module.chunks[.function(module.name, "0.talk", [])]!
		try #expect(main.disassemble(in: module) == Instructions(
			// Dict literal
			.op(.constant, line: 0, .constant(.int(321))),
			.op(.constant, line: 0, .constant(.int(654))),
			.op(.constant, line: 0, .constant(.int(123))),
			.op(.constant, line: 0, .constant(.int(456))),
			.op(.initDict, line: 0, .dictionary(count: 2)),

			.op(.setModuleValue, line: 0, .global(.value("E2E", "a"))),

			// Subscript arg
			.op(.constant, line: 1, .constant(.int(789))),
			.op(.invokeMethod, line: 1, .invokeMethod(.method("Standard", "Dictionary", "set", ["T", "T"]))),

			.op(.returnVoid, line: 0)
		))
	}
}
