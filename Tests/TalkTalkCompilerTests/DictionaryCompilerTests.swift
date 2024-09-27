//
//  DictionaryCompilerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/22/24.
//

import TalkTalkBytecode
import TalkTalkCompiler
import Testing

@Suite(.disabled()) struct DictionaryCompilerTests: CompilerTest {
	@Test("Compiles dictionary") func testDictionary() async throws {
		let module = try compile("""
		[123: 456, 321: 654]
		""")

		try #expect(module.main!.disassemble(in: module) == Instructions(
			// Emit elements onto the stack
			.op(.constant, line: 0, .constant(.int(123))),
			.op(.constant, line: 0, .constant(.int(456))),
			.op(.constant, line: 0, .constant(.int(321))),
			.op(.constant, line: 0, .constant(.int(654))),
			.op(.initDict, line: 0),
			.op(.pop, line: 0),
			.op(.returnValue, line: 0)
		))
	}

	@Test("Compiles dictionary getter") func testDictionaryGetter() async throws {
		let module = try compile("""
			[123: 456, 321: 654][789]
			"""
		)

		try #expect(module.main!.disassemble(in: module) == Instructions(
			.op(.constant, line: 0, .constant(.int(789))),
			.op(.constant, line: 0, .constant(.int(123))),
			.op(.constant, line: 0, .constant(.int(456))),
			.op(.constant, line: 0, .constant(.int(321))),
			.op(.constant, line: 0, .constant(.int(654))),
			.op(.initDict, line: 0),
			.op(.getProperty, line: 0, .getProperty(Symbol.method("Standard", "Dictionary", "get", ["index"]).asStatic())),
			.op(.call, line: 0),
			.op(.pop, line: 0),
			.op(.returnValue, line: 0)
		))
	}

	@Test("Compiles dictionary setter") func testDictionarySetter() async throws {
		let module = try compile("""
			[123: 456, 321: 654][789]
			"""
		)

		try #expect(module.main!.disassemble(in: module) == Instructions(
			.op(.constant, line: 0, .constant(.int(789))),
			.op(.constant, line: 0, .constant(.int(123))),
			.op(.constant, line: 0, .constant(.int(456))),
			.op(.constant, line: 0, .constant(.int(321))),
			.op(.constant, line: 0, .constant(.int(654))),
			.op(.initDict, line: 0),
			.op(.getProperty, line: 0, .getProperty(Symbol.method("Standard", "Dictionary", "get", ["index"]).asStatic())),
			.op(.call, line: 0),
			.op(.pop, line: 0),
			.op(.returnValue, line: 0)
		))
	}
}
