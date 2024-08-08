//
//  ModuleTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import Testing
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkSyntax
import TalkTalkAnalysis

actor ModuleTests {
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

	@Test("Encode", .disabled("we'll get to this")) func encode() {
		_ = compile(name: "Encoding", [.tmp("func foo() { 123 }"), .tmp("func bar() { foo() }")])

	}
}
