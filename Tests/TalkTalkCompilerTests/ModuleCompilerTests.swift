//
//  ModuleCompilerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode
import TalkTalkAnalysis
import TalkTalkCompiler
import TalkTalkSyntax
import Testing

actor ModuleCompilerTests {
	func compile(files: [ParsedSourceFile]) -> Module {
		try! ModuleCompiler(name: "CompilerTests", files: files).compile()
	}

	@Test("Can compile a module") func basic() {
		let files: [ParsedSourceFile] = [
			.tmp("""
			func foo() {
				bar()
			}
			"""),
			.tmp("""
			func bar() {
				123
			}
			""")
		]

		let module = compile(files: files)
		#expect(module.name == "CompilerTests")
		#expect(module.chunks.count == 2)
	}
}
