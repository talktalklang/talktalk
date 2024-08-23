//
//  DictionaryCompilerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/22/24.
//

import Testing
import TalkTalkBytecode
import TalkTalkCompiler

struct DictionaryCompilerTests: CompilerTest {
	@Test("Compiles dictionary") func testDictionary() async throws {
		let module = try compile("""
		[123: 456, 321: 654]
		""")

		#expect(module.chunks[0].disassemble(in: module) == Instructions(
			// Emit elements onto the stack
			.op(.constant, line: 0, .constant(.int(123))),
			.op(.constant, line: 0, .constant(.int(456))),
			.op(.constant, line: 0, .constant(.int(321))),
			.op(.constant, line: 0, .constant(.int(654))),
			.op(.initDict, line: 0),
			.op(.pop, line: 0),
			.op(.return, line: 0)
		))
	}

	@Test("Compiles dictionary getter") func testDictionaryGetter() async throws {
		let module = try compile("""
			[123: 456, 321: 654][789]
			"""
		)

		#expect(module.chunks[0].disassemble(in: module) == Instructions(
			.op(.constant, line: 0, .constant(.int(789))),
			.op(.constant, line: 0, .constant(.int(123))),
			.op(.constant, line: 0, .constant(.int(456))),
			.op(.constant, line: 0, .constant(.int(321))),
			.op(.constant, line: 0, .constant(.int(654))),
			.op(.initDict, line: 0),
			.op(.getProperty, line: 0, .getProperty(slot: 0, options: .isMethod)),
			.op(.call, line: 0),
			.op(.pop, line: 0),
			.op(.return, line: 0)
		))
	}

	@Test("Compiles dictionary setter") func testDictionarySetter() async throws {
		let module = try compile("""
			[123: 456, 321: 654][789]
			"""
		)

		#expect(module.chunks[0].disassemble(in: module) == Instructions(
			.op(.constant, line: 0, .constant(.int(789))),
			.op(.constant, line: 0, .constant(.int(123))),
			.op(.constant, line: 0, .constant(.int(456))),
			.op(.constant, line: 0, .constant(.int(321))),
			.op(.constant, line: 0, .constant(.int(654))),
			.op(.initDict, line: 0),
			.op(.getProperty, line: 0, .getProperty(slot: 0, options: .isMethod)),
			.op(.call, line: 0),
			.op(.pop, line: 0),
			.op(.return, line: 0)
		))
	}
}
