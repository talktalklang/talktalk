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
	let analyses: [String: AnalysisModule]
	let modules: [String: Module]

	public init(
		compilationUnit: CompilationUnit,
		mode: CompilationMode = .module,
		analyses: [String: AnalysisModule],
		modules: [String: Module]
	) {
		self.compilationUnit = compilationUnit
		self.mode = mode
		self.analyses = analyses
		self.modules = modules
	}

	func run() async throws -> CompilationResult {
		let sourceFiles = try compilationUnit.files.map {
			return try SourceFile(path: $0.path, text: String(contentsOf: $0, encoding: .utf8))
		}

		let parsedSourceFiles = try sourceFiles.map {
			try ParsedSourceFile(path: $0.path, syntax: Parser.parse($0))
		}

		let analysisModule = try ModuleAnalyzer(
			name: compilationUnit.name,
			files: Set(parsedSourceFiles),
			moduleEnvironment: analyses,
			importedModules: Array(analyses.values)
		).analyze()

		let module = try ModuleCompiler(
			name: compilationUnit.name,
			analysisModule: analysisModule,
			moduleEnvironment: modules
		).compile(mode: mode)

		return CompilationResult(module: module, analysis: analysisModule)
	}
}
