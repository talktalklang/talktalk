//
//  EnumTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/6/24.
//

import Testing
import TalkTalkBytecode

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

		try #expect(module.chunks[.function(module.name, "0.talk", [])]!.disassemble(in: module) == Instructions(
			.op(.constant, line: 5, .constant(.int(123))),
			.op(.getEnum, line: 5, .enum(Symbol.enum(module.name, "Thing").asStatic())),
			.op(.getProperty, line: 5, .getProperty(Symbol.property(module.name, "Thing", "foo").asStatic())),
			.op(.call, line: 5),
			.op(.pop, line: 5),
			.op(.returnVoid, line: 0)
		))
	}
}
