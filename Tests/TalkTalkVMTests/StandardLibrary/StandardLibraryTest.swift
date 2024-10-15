//
//  StandardLibraryTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import Foundation
import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompilerV1
import TalkTalkCore
import TalkTalkCore
import TalkTalkVM

@MainActor
protocol StandardLibraryTest {}

extension StandardLibraryTest {
	func run(
		_ input: String,
		analysisEnvironment: [String: AnalysisModule] = [:],
		moduleEnvironment: [String: Module] = [:],
		verbosity: Verbosity = .quiet,
		output: any OutputBuffer = DefaultOutputBuffer()
	) async throws -> VirtualMachine.ExecutionResult {
		let files: [ParsedSourceFile] = [.tmp(input, "1.talk")]
		let analyzer = try ModuleAnalyzer(
			name: "StdLibTest",
			files: files,
			moduleEnvironment: analysisEnvironment,
			importedModules: []
		)
		let analyzed = try analyzer.analyze()
		let errors = try analyzed.collectErrors()

		if !errors.isEmpty {
			throw CompilerError.analysisError(errors.all.map { "\($0)" }.joined(separator: ", "))
		}

		let module = try ModuleCompiler(
			name: "StdLibTest",
			analysisModule: analyzed,
			moduleEnvironment: moduleEnvironment
		).compile(mode: .executable)

		return try VirtualMachine.run(module: module, verbosity: verbosity, output: output)
	}
}
