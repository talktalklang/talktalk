//
//  StandardLibraryTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/31/24.
//

import Testing

struct StandardLibraryTests: CompilerTest {
	@Test("Can compile array") func array() throws {
		let module = try compile(
			"""
			let a = [1,2,3]
			"""
		)

		let main = module.chunks[.function(module.name, "0.talk", [])]!

		try #expect(main.disassemble(in: module) == Instructions(
			.op(.constant, line: 0, .constant(.int(3))),
			.op(.constant, line: 0, .constant(.int(2))),
			.op(.constant, line: 0, .constant(.int(1))),
			.op(.initArray, line: 0, .array(count: 3)),
			.op(.setModuleValue, line: 0, .global(.value(module.name, "a"))),
			.op(.returnVoid, line: 0)
		))
	}

	@Test("Can append to array") func arrayAppend() throws {
		let module = try compile(
			"""
			var a = []
			a.append(123)
			return a.count
			"""
		)

		let main = module.chunks[.function(module.name, "0.talk", [])]!

		// TODO: Something's weird here, this should all be in the value initializer
		try #expect(main.disassemble(in: module) == Instructions(
			.op(.initArray, line: 0, .array(count: 0)),
			.op(.setModuleValue, line: 0, .global(.value("E2E", "a"))),
			.op(.constant, line: 1, .constant(.int(123))),
			.op(.getModuleValue, line: 1, .global(.value("E2E", "a"))),
			.op(.invokeMethod, line: 1, .invokeMethod(.method("Standard", "Array", "append", ["T"]))),
			.op(.getModuleValue, line: 2, .global(.value("E2E", "a"))),
			.op(.getProperty, line: 2, .getProperty(.property("Standard", "Array", "count"), options: [])),
			.op(.returnValue, line: 2),
			.op(.returnVoid, line: 0)
		))
	}
}
