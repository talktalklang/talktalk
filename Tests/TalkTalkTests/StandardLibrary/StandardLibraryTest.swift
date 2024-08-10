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
		verbose: Bool = false
	) async throws -> VirtualMachine.ExecutionResult {
		let stdlibURL = URL.homeDirectory.appending(path: "apps/talktalk/Library/Standard")
		let stdlib = try await Driver(directories: [stdlibURL]).compile()["Standard"]!

		let files: [ParsedSourceFile] = [.tmp(input)]
		let analysis = ["Standard": stdlib.analysis]
		let analyzed = try ModuleAnalyzer(name: "StdLibTest", files: files, moduleEnvironment: analysis).analyze()

		let module = try ModuleCompiler(name: "StdLibTest", analysisModule: analyzed, moduleEnvironment: ["Standard": stdlib.module]).compile(mode: .executable)
		return VirtualMachine.run(module: module, verbose: verbose)
	}
}