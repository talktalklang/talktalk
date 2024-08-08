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
	func compile(_ files: [ParsedSourceFile]) -> Module {
		let analyzed = try! ModuleAnalyzer(name: "CompilerTests", files: files).analyze()
		return try! ModuleCompiler(name: "CompilerTests", analysisModule: analyzed).compile()
	}

	@Test("Can compile a module") func basic() {
		let files: [ParsedSourceFile] = [
			.tmp("""
			func fizz() {}

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

		let module = compile(files)
		#expect(module.name == "CompilerTests")

		#expect(module.chunks.map(\.name).sorted() == ["fizz", "foo", "bar"].sorted())

		// We want each global function to have its own chunk in the module
		#expect(module.chunks.count == 3)
	}
}
