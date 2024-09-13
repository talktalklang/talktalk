//
//  StringTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/13/24.
//

import Testing

struct StringTests: CompilerTest {
	@Test("Basic string interpolation") func basicInterpolation() throws {
		let module = try compile(#"""
		"foo \(123)"
		"""#
		)

		try #expect(module.chunks[.function(module.name, "0.tlk", [])]!.disassemble(in: module) == Instructions(
			.op(.data, line: 0, .data(.init(kind: .string, bytes: [UInt8]("foo ".utf8)))),
			.op(.constant, line: 0, .constant(.int(123))),
			.op(.appendInterpolation, line: 0),
			.op(.data, line: 0, .data(.init(kind: .string, bytes: []))),
			.op(.appendInterpolation, line: 0),
			.op(.pop, line: 0),
			.op(.returnVoid, line: 0)
		))
	}
}
