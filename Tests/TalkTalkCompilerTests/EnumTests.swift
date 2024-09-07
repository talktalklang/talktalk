//
//  EnumTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/6/24.
//

import Testing

struct EnumTests: CompilerTest {
	@Test("Basic enum") func basic() throws {
		let module = try compile("""
			enum Thing {
				case foo(int)
				case bar(String)
			}

			Thing.foo(123)
			"""
		)

		try #expect(module.chunks[0].disassemble(in: module) == Instructions(
			.op(.constant, line: 5, .constant(.int(123))),
			.op(.getEnumCase, line: 5, .enum(enum: 0, case: 0)),
			.op(.call, line: 5),
			.op(.pop, line: 5),
			.op(.return, line: 0)
		))
	}
}
