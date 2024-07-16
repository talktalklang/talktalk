//
//  CompilerTests.swift
//
//
//  Created by Pat Nakajima on 7/15/24.
//
import Testing
import TalkTalkCompiler

struct CompilerTests {
	@Test("Can compile") func basic() {
		let compiler = Compiler(source: "print(1)")
		compiler.compile()
	}
}
