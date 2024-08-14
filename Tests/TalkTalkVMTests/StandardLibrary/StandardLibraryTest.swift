//
//  StandardLibraryTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import Foundation
import TalkTalkCore
import TalkTalkDriver
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkVM
import TalkTalkAnalysis
import TalkTalkSyntax

protocol StandardLibraryTest {}

extension StandardLibraryTest {
	func run(
		_ input: String,
		analysisEnvironment: [String: AnalysisModule] = [:],
		moduleEnvironment: [String: Module] = [:],
		verbosity: Verbosity = .quiet
	) async throws -> VirtualMachine.ExecutionResult {
		let files: [ParsedSourceFile] = [.tmp(input)]
		let analyzer = ModuleAnalyzer(
			name: "StdLibTest",
			files: files,
			moduleEnvironment: analysisEnvironment
		)
		let analyzed = try analyzer.analyze()

		if !analyzer.errors.isEmpty {
			throw CompilerError.analysisError(analyzer.errors.map { "\($0)" }.joined(separator: ", "))
		}

		// The Driver normally does this part but since we're not using it in here, we need
		// to add the stdlib
		var moduleEnvironment = moduleEnvironment
		let driver = Driver(directories: [Library.standardLibraryURL])
		let stdlib = try await driver.compile()["Standard"]!.module
		moduleEnvironment["Standard"] = stdlib

		let module = try ModuleCompiler(
			name: "StdLibTest",
			analysisModule: analyzed,
			moduleEnvironment: moduleEnvironment
		).compile(mode: .executable)

		return VirtualMachine.run(module: module, verbosity: verbosity)
	}
}
