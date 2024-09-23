//
//  IteratorTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/20/24.
//

import Testing

struct IteratorTests: CompilerTest {
	@Test("Basic iterable") func iterable() throws {
		let module = try compile(
			"""
			for i in [1, 2, 3, 4] {
				print(i)
			}
			"""
		)

		try #expect(module.chunks[.function(module.name, "0.talk", [])]!.disassemble(in: module) == Instructions(
			// Start a new scope for this for loop
			.op(.beginScope, line: 0),

			// Emit the sequence value
			.op(.constant, line: 0, .constant(.int(4))),
			.op(.constant, line: 0, .constant(.int(3))),
			.op(.constant, line: 0, .constant(.int(2))),
			.op(.constant, line: 0, .constant(.int(1))),
			.op(.initArray, line: 0, .array(count: 4)),

			// Emit the code to get the iterator from the sequence
			.op(.getProperty, line: 0, .getProperty(.method("Standard", "Array", "makeIterator", []), options: .isMethod)),
			.op(.call, line: 0),

			// Stash the iterator in a local
			.op(.setLocal, line: 0, .local(.value(module.name, "$iterator"))),

			// Start the loop
			.op(.getLocal, line: 0, .local(.value(module.name, "$iterator"))),
			.op(.getProperty, line: 0, .getProperty(.method("Standard", nil, "next", []), options: .isMethod)),
			.op(.call, line: 0),
			// Stash the value
			.op(.setLocal, line: 0, .local(.value(module.name, "$current"))),

			// See if next() returned none
			.op(.none, line: 0),
			.op(.notEqual, line: 0),

			// If it returned nil, jump past the body
			.op(.jumpUnless, line: 0, .jump(offset: 13)),

			// Pop the bool condition result
			.op(.pop, line: 0),

			// Bind the value
			.op(.getLocal, line: 0, .local(.value(module.name, "$current"))),
			.op(.setLocal, line: 0, .local(.value(module.name, "i"))),

			// Emit the body
			.op(.getLocal, line: 1, .local(.value(module.name, "i"))),
			.op(.getBuiltin, line: 1, .builtin(.function("[builtin]", "print", ["any"]))),
			.op(.call, line: 1),
			.op(.loop, line: 1, .loop(back: 26)),

			.op(.returnVoid, line: 0)
		))
	}
}
