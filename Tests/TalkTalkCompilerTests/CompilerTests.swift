//
//  CompilerTests.swift
//
//
//  Created by Pat Nakajima on 7/15/24.
//
import Testing
import TalkTalkCompiler

struct CompilerTests {
	@Test("Can compile") func basic() throws {
		let compiler = Compiler(source: "1 + 2")
		try compiler.compile()
	}
}
