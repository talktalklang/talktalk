//
//  StandardLibraryTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import Foundation
import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkCore
import TalkTalkDriver
import TalkTalkSyntax
import TalkTalkVM

@MainActor
protocol StandardLibraryTest {}

extension StandardLibraryTest {
	func run(
		_ input: String,
		analysisEnvironment: [String: AnalysisModule] = [:],
		moduleEnvironment: [String: Module] = [:],
		verbosity: Verbosity = .quiet
	) async throws -> VirtualMachine.ExecutionResult {
		let stdlib = try await StandardLibrary.compile()
		var moduleEnvironment = moduleEnvironment
		var analysisEnvironment = analysisEnvironment
		moduleEnvironment["Standard"] = stdlib.module
		analysisEnvironment["Standard"] = stdlib.analysis

		let files: [ParsedSourceFile] = [.tmp(input, "1.tlk")]
		let analyzer = ModuleAnalyzer(
			name: "StdLibTest",
			files: Set(files),
			moduleEnvironment: analysisEnvironment,
			importedModules: [stdlib.analysis]
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

		return VirtualMachine.run(module: module, verbosity: verbosity)
	}
}
