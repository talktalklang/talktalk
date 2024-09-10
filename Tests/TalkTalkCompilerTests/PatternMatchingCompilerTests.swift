//
//  PatternMatchingCompilerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/6/24.
//

import Testing

struct PatternMatchingCompilerTests: CompilerTest {
	@Test("Basic") func basic() throws {
		let module = try compile("""
			match true {
			case false:
				return 123
			case true:
				return 456
			}
			"""
		)

		try #expect(module.chunks[.function(module.name, "0.tlk", [])]!.disassemble(in: module) == Instructions(
			// Emit the target to match
			.op(.true, line: 0),

			// Ok we're starting a pattern match
			.op(.matchBegin, line: 0),

			// Emit the first pattern
			.op(.false, line: 1),
			.op(.matchCase, line: 1, .jump(offset: 4)),

			// Emit the second pattern
			.op(.true, line: 3),
			.op(.matchCase, line: 3, .jump(offset: 6)),

			// Emit the first body we'd jump to if the first case is true
			.op(.constant, line: 2, .constant(.int(123))),
			.op(.returnValue, line: 2),
			.op(.jump, line: 2, .jump(offset: 6)),

			// Emit the second body we'd jump to if the second case is true
			.op(.constant, line: 4, .constant(.int(456))),
			.op(.returnValue, line: 4),
			.op(.jump, line: 4, .jump(offset: 0)),

			.op(.returnVoid, line: 0)
		))
	}

	@Test("var binding") func varBinding() throws {
		let module = try compile("""
			enum Thing { case foo(int) }

			match Thing.foo(123) {
			case .foo(let a):
				return a
			}
			"""
		)

		try #expect(module.chunks[.function(module.name, "0.tlk", [])]!.disassemble(in: module) == Instructions(
			// Get the target
			.op(.constant, line: 2, .constant(.int(123))),
			.op(.getEnum, line: 2, .enum(.enum(module.name, "Thing"))),
			.op(.call, line: 2),

			// Ok we're starting a pattern match
			.op(.matchBegin, line: 0),

			// Emit the pattern
			.op(.getEnum, line: 2, .enum(.enum(module.name, "Thing"))),
			.op(.matchCase, line: 1, .jump(offset: 4)),

			// Emit the body we'd jump to if the first case is true

			// Bind the `let a` for the block
			.op(.constant, line: 2, .constant(.int(123))),
			.op(.setLocal, line: 3, .local(.value(module.name, "a"))),

			// Emit the actual code for the block
			.op(.getLocal, line: 3, .local(.value(module.name, "a"))),
			.op(.returnValue, line: 3),
			.op(.jump, line: 3, .jump(offset: 6)),

			.op(.returnVoid, line: 0)
		))
	}
}
