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
			.op(.matchBegin, line: 0),

			// Emit the first pattern
			.op(.true, line: 0),
			.op(.false, line: 1),
			.op(.equal, line: 1),
			.op(.matchCase, line: 1, .jump(offset: 6)),

			// Emit the second pattern
			.op(.true, line: 0),
			.op(.true, line: 3),
			.op(.equal, line: 3),
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
			enum Thing {
			case foo(int)
			case bar(String)
			}

			match Thing.foo(123) {
			case .foo(let a):
				return a
			case .bar(let b):
				return b
			}
			"""
		)

		try #expect(module.chunks[.function(module.name, "0.tlk", [])]!.disassemble(in: module) == Instructions(
			.op(.matchBegin, line: 5),

			// Emit the first pattern
			.op(.getEnum, line: 5, .enum(.enum(module.name, "Thing"))),
			.op(.getProperty, line: 5, .getProperty(.property(module.name, "Thing", "foo"), options: [])),
			.op(.getEnum, line: 6, .enum(.enum(module.name, "Thing"))),
			.op(.getProperty, line: 6, .getProperty(.property(module.name, "Thing", "foo"), options: [])),

			.op(.equal, line: 6),
			.op(.matchCase, line: 6, .jump(offset: 14)),

			// Emit the second pattern
			.op(.getEnum, line: 5, .enum(.enum(module.name, "Thing"))),
			.op(.getProperty, line: 5, .getProperty(.property(module.name, "Thing", "foo"), options: [])),
			.op(.getEnum, line: 8, .enum(.enum(module.name, "Thing"))),
			.op(.getProperty, line: 8, .getProperty(.property(module.name, "Thing", "bar"), options: [])),

			.op(.equal, line: 8),
			.op(.matchCase, line: 8, .jump(offset: 10)),

			// Emit the body we'd jump to if the first case is true

			// Bind the `let a` for the first block
			.op(.constant, line: 5, .constant(.int(123))),
			.op(.setLocal, line: 6, .local(.value(module.name, "a"))),

			// Emit the actual code for the first block
			.op(.getLocal, line: 7, .local(.value(module.name, "a"))),
			.op(.returnValue, line: 7),
			.op(.jump, line: 7, .jump(offset: 10)),

			// Bind the `let b` for the second block
			.op(.constant, line: 5, .constant(.int(123))),
			.op(.setLocal, line: 8, .local(.value(module.name, "b"))),

			// Emit the actual code for the second block
			.op(.getLocal, line: 9, .local(.value(module.name, "b"))),
			.op(.returnValue, line: 9),
			.op(.jump, line: 9, .jump(offset: 0)),

			.op(.returnVoid, line: 0)
		))
	}
}
