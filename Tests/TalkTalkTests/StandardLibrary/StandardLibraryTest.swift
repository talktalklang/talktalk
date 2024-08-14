//
//  StandardLibraryTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import Foundation
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

		print(#file)
		let stdlibURL = Driver.standardLibraryURL
		print(try FileManager.default.contentsOfDirectory(atPath: stdlibURL.path))

		let stdlib = try await Driver(directories: [stdlibURL]).compile()["Standard"]!

		let files: [ParsedSourceFile] = [.tmp(input)]
		let analysis = ["Standard": stdlib.analysis]
		let analyzer = ModuleAnalyzer(name: "StdLibTest", files: files, moduleEnvironment: analysis)
		let analyzed = try analyzer.analyze()

		if !analyzer.errors.isEmpty {
			throw CompilerError.analysisError(analyzer.errors.map { "\($0)" }.joined(separator: ", "))
		}

		let module = try ModuleCompiler(name: "StdLibTest", analysisModule: analyzed, moduleEnvironment: ["Standard": stdlib.module]).compile(mode: .executable)

		return VirtualMachine.run(module: module, verbosity: verbosity)
	}
}
