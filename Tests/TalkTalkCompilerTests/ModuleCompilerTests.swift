//
//  ModuleCompilerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkSyntax
import Testing

actor ModuleCompilerTests {
	func compile(
		name: String,
		_ files: [ParsedSourceFile],
		analysisEnvironment: [String: AnalysisModule] = [:],
		moduleEnvironment: [String: Module] = [:]
	) -> (Module, AnalysisModule) {
		let analysis = moduleEnvironment.reduce(into: [:]) { res, tup in res[tup.key] = analysisEnvironment[tup.key] }
		let analyzed = try! ModuleAnalyzer(name: name, files: files, moduleEnvironment: analysis).analyze()
		let module = try! ModuleCompiler(name: name, analysisModule: analyzed, moduleEnvironment: moduleEnvironment).compile()
		return (module, analyzed)
	}

	@Test("Can compile module functions") func basic() {
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

		let (module, _) = compile(name: "CompilerTests", files)
		#expect(module.name == "CompilerTests")

		#expect(module.chunks.map(\.name).sorted() == ["fizz", "foo", "bar"].sorted())

		// We want each global function to have its own chunk in the module
		#expect(module.chunks.count == 3)
	}

	@Test("Can compile module global values") func globalValues() throws {
		let files: [ParsedSourceFile] = [
			.tmp("""
			fizz = 123
			"""),
			.tmp("""
			func bar() {
				fizz
			}
			""")
		]

		let (module, _) = compile(name: "CompilerTests", files)
		#expect(module.name == "CompilerTests")

		#expect(module.chunks.map(\.name).sorted() == ["bar"].sorted())
		#expect(module.chunks.count == 1)
		print(module.symbols)

		let fizzSlot = try #require(module.symbols[.value("fizz")])
		#expect(module.valueInitializers[Byte(fizzSlot)] != nil)
	}

	@Test("Can import module functions") func importing() {
		let (moduleA, analysisA) = compile(
			name: "A",
			[
				.tmp("func foo() { 123 }")
			]
		)
		let (moduleB, _) = compile(
			name: "B",
			[
				.tmp("""
					import A

					func bar() {
						foo()
					}
					"""
				)
			],
			analysisEnvironment: ["A": analysisA],
			moduleEnvironment: ["A": moduleA]
		)

		#expect(moduleB.chunks.count == 2)
		#expect(moduleB.chunks.map(\.name).sorted() == ["bar", "foo"].sorted())
	}
}
