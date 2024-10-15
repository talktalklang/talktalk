//
//  VMTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/2/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompilerV1
import TalkTalkCore
import TalkTalkCore
import TalkTalkVM
import Testing

@MainActor
protocol VMTest {}

extension VMTest {
	func compile(_ strings: String...) throws -> Module {
		try compile(strings)
	}

	func compile(_ strings: [String]) throws -> Module {
		let analysisModule = try ModuleAnalyzer(
			name: "E2E",
			files: strings.enumerated().map { .tmp($1, "\($0).talk") },
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
		let analyzed = try ModuleAnalyzer(
			name: name,
			files: files,
			moduleEnvironment: analysisEnvironment,
			importedModules: []
		).analyze()

		let module = try ModuleCompiler(
			name: name,
			analysisModule: analyzed,
			moduleEnvironment: moduleEnvironment
		).compile(mode: .executable)
		return (module, analyzed)
	}

	func run(_ strings: String..., verbosity: Verbosity = .quiet, output: any OutputBuffer = DefaultOutputBuffer()) throws -> TalkTalkBytecode.Value {
		let module = try compile(strings)
		return try VirtualMachine.run(module: module, verbosity: verbosity, output: output).get()
	}

	func returning(_ string: String, verbosity: Verbosity = .quiet) throws -> TalkTalkBytecode.Value {
		try run("return \(string)", verbosity: verbosity)
	}
}
