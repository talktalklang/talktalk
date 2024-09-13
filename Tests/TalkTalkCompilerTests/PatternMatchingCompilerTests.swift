//
//  PatternMatchingCompilerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/6/24.
//

import Testing
import TalkTalkBytecode

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

		let matchSymbol = Symbol.function(module.name, "match#SyntaxID(9, 0.tlk)", [])

		try #expect(module.chunks[matchSymbol]!.disassemble(in: module) == Instructions(
			// Emit the first pattern
			.op(.true, line: 0),
			.op(.false, line: 1),
			.op(.match, line: 1),
			.op(.matchCase, line: 1, .jump(offset: 8)),
			.op(.pop, line: 1),

			// Emit the second pattern
			.op(.true, line: 0),
			.op(.true, line: 3),
			.op(.match, line: 3),
			.op(.matchCase, line: 3, .jump(offset: 7)),
			.op(.pop, line: 3),

			// Emit the first body we'd jump to if the first case is true
			.op(.constant, line: 2, .constant(.int(123))),
			.op(.returnValue, line: 2),
			.op(.jump, line: 2, .jump(offset: 6)),

			// Emit the second body we'd jump to if the second case is true
			.op(.constant, line: 4, .constant(.int(456))),
			.op(.returnValue, line: 4),
			.op(.jump, line: 4, .jump(offset: 0)),

			.op(.endInline, line: 0)
		))


		try #expect(module.chunks[.function(module.name, "0.tlk", [])]!.disassemble(in: module) == Instructions(
			.op(.matchBegin, line: 0, .variable(matchSymbol, .matchBegin)),
			.op(.returnVoid, line: 0)
		))
	}

	@Test("Basic with else") func basicElse() throws {
		let module = try compile("""
			match true {
			case false:
				return 123
			else:
				return 456
			}
			"""
		)

		let matchSymbol = Symbol.function(module.name, "match#SyntaxID(8, 0.tlk)", [])

		try #expect(module.chunks[.function(module.name, "0.tlk", [])]!.disassemble(in: module) == Instructions(
			.op(.matchBegin, line: 0, .variable(matchSymbol, .matchBegin)),
			.op(.returnVoid, line: 0)
		))

		try #expect(module.chunks[matchSymbol]!.disassemble(in: module) == Instructions(
			// Emit the first pattern
			.op(.true, line: 0),
			.op(.false, line: 1),
			.op(.match, line: 1),
			.op(.matchCase, line: 1, .jump(offset: 8)),
			.op(.pop, line: 1),

			// Emit the else pattern
			.op(.true, line: 3),
			.op(.true, line: 3),
			.op(.match, line: 3),
			.op(.matchCase, line: 3, .jump(offset: 7)),
			.op(.pop, line: 3),

			// Emit the first body we'd jump to if the first case is true
			.op(.constant, line: 2, .constant(.int(123))),
			.op(.returnValue, line: 2),
			.op(.jump, line: 2, .jump(offset: 6)),

			// Emit the else body that we should jump to instead
			.op(.constant, line: 4, .constant(.int(456))),
			.op(.returnValue, line: 4),
			.op(.jump, line: 4, .jump(offset: 0)),

			.op(.endInline, line: 0)
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

		let matchSymbol = Symbol.function(module.name, "match#SyntaxID(25, 0.tlk)", [])

		try #expect(module.chunks[.function(module.name, "0.tlk", [])]!.disassemble(in: module) == Instructions(
			.op(.matchBegin, line: 5, .variable(matchSymbol, .matchBegin)),
			.op(.returnVoid, line: 0)
		))

		try #expect(module.chunks[matchSymbol]!.disassemble(in: module) == Instructions(
			// Emit the first pattern
			.op(.constant, line: 5, .constant(.int(123))),
			.op(.getEnum, line: 5, .enum(.enum(module.name, "Thing"))),
			.op(.getProperty, line: 5, .getProperty(.property(module.name, "Thing", "foo"), options: [])),
			.op(.call, line: 5),
			.op(.binding, line: 6, .binding(.value(module.name, "a"))),
			.op(.getEnum, line: 6, .enum(.enum(module.name, "Thing"))),
			.op(.getProperty, line: 6, .getProperty(.property(module.name, "Thing", "foo"), options: [])),
			.op(.call, line: 6),

			.op(.match, line: 6),
			.op(.matchCase, line: 6, .jump(offset: 22)),
			.op(.pop, line: 6),

			// Emit the second pattern
			.op(.constant, line: 5, .constant(.int(123))),
			.op(.getEnum, line: 5, .enum(.enum(module.name, "Thing"))),
			.op(.getProperty, line: 5, .getProperty(.property(module.name, "Thing", "foo"), options: [])),
			.op(.call, line: 5),
			.op(.binding, line: 8, .binding(.value(module.name, "b"))),
			.op(.getEnum, line: 8, .enum(.enum(module.name, "Thing"))),
			.op(.getProperty, line: 8, .getProperty(.property(module.name, "Thing", "bar"), options: [])),
			.op(.call, line: 8),

			.op(.match, line: 8),
			.op(.matchCase, line: 8, .jump(offset: 11)),
			.op(.pop, line: 8),
			.op(.binding, line: 6, .binding(.value(module.name, "a"))),

			// Emit the body we'd jump to if the first case is true

			// Bind the `let a` for the first block
			.op(.setLocal, line: 6, .local(.value(module.name, "a"))),
			.op(.getLocal, line: 7, .local(.value(module.name, "a"))),
			.op(.returnValue, line: 7),
			.op(.jump, line: 7, .jump(offset: 10)),

			// Bind the `let b` for the second block
			.op(.binding, line: 8, .binding(.value(module.name, "b"))),
			.op(.setLocal, line: 8, .local(.value(module.name, "b"))),
			.op(.getLocal, line: 9, .local(.value(module.name, "b"))),
			.op(.returnValue, line: 9),
			.op(.jump, line: 9, .jump(offset: 0)),

			.op(.endInline, line: 5)
		))
	}
}
