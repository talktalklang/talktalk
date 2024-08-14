//
//  Pipeline.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import TalkTalkCore
import TalkTalkAnalysis
import TalkTalkCompiler
import TalkTalkBytecode
import TalkTalkSyntax

struct Pipeline {
	let compilationUnit: CompilationUnit
	let mode: CompilationMode
	let isBootstrap: Bool

	public init(
		compilationUnit: CompilationUnit,
		mode: CompilationMode = .module,
		isBootstrap: Bool = false) {
		self.compilationUnit = compilationUnit
		self.mode = mode
		self.isBootstrap = isBootstrap
	}

	func run() async throws -> CompilationResult {
		let moduleEnvironment: [String: Module]

		if !isBootstrap {
			let driver = Driver(
				directories: [Library.standardLibraryURL],
				isBootstrap: true
			)
			let stdlib = try await driver.compile()["Standard"]!
			moduleEnvironment = ["Standard": stdlib.module]
		} else {
			moduleEnvironment = [:]
		}

		let sourceFiles = try compilationUnit.files.map {
			try SourceFile(path: $0.path, text: String(contentsOf: $0, encoding: .utf8))
		}

		let parsedSourceFiles = try sourceFiles.map {
			try ParsedSourceFile(path: $0.path, syntax: Parser.parse($0.text))
		}

		let analysisModule = try ModuleAnalyzer(
			name: compilationUnit.name,
			files: parsedSourceFiles,
			moduleEnvironment: [:]
		).analyze()

		let module = try ModuleCompiler(
			name: compilationUnit.name,
			analysisModule: analysisModule,
			moduleEnvironment: moduleEnvironment
		).compile(mode: mode)

		return CompilationResult(module: module, analysis: analysisModule)
	}
}
