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

		let main = module.chunks[0]

		// TODO: Something's weird here, this should all be in the value initializer
		#expect(main.disassemble(in: module) == Instructions(
			.op(.constant, line: 0, .constant(.int(3))),
			.op(.constant, line: 0, .constant(.int(2))),
			.op(.constant, line: 0, .constant(.int(1))),
			.op(.initArray, line: 0, .array(count: 3))
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

		let main = module.chunks[0]

		// TODO: Something's weird here, this should all be in the value initializer
		#expect(main.disassemble(in: module) == Instructions(
			.op(.constant, line: 0, .constant(.int(3))),
			.op(.constant, line: 0, .constant(.int(2))),
			.op(.constant, line: 0, .constant(.int(1))),
			.op(.initArray, line: 0, .array(count: 3))
		))
	}
}
