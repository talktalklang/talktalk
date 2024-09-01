//
//  CompilerTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/21/24.
//

import Testing
import TalkTalkCore
import TalkTalkCompiler
import TalkTalkSyntax
import TalkTalkAnalysis
import TalkTalkBytecode

protocol CompilerTest {}

extension CompilerTest {
	func compile(_ strings: String...) throws -> Module {
		let analysisModule = try ModuleAnalyzer(
			name: "E2E",
			files: strings.enumerated().map { .tmp($1, "\($0).tlk") },
			moduleEnvironment: [:],
			importedModules: []
		).analyze()

		let compiler = ModuleCompiler(name: "E2E", analysisModule: analysisModule, moduleEnvironment: [:])
		return try compiler.compile(mode: .executable)
	}

	func compile(
		name: String,
		_ files: [ParsedSourceFile],
		analysisEnvironment: [String: AnalysisModule] = [:],
		moduleEnvironment: [String: Module] = [:]
	) throws -> (Module, AnalysisModule) {
		let analysis = moduleEnvironment.reduce(into: [:]) { res, tup in res[tup.key] = analysisEnvironment[tup.key] }
		let analyzed = try ModuleAnalyzer(
			name: name,
			files: files,
			moduleEnvironment: analysis,
			importedModules: Array(analysisEnvironment.values)
		).analyze()

		let module = try ModuleCompiler(
			name: name,
			analysisModule: analyzed,
			moduleEnvironment: moduleEnvironment
		).compile(mode: .executable)

		return (module, analyzed)
	}
}
