//
//  Pipeline.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkCore
import TalkTalkSyntax

struct Pipeline {
	let compilationUnit: CompilationUnit
	let mode: CompilationMode
	let analyses: [String: AnalysisModule]
	let modules: [String: Module]
	let allowErrors: Bool

	public init(
		compilationUnit: CompilationUnit,
		mode: CompilationMode = .module,
		analyses: [String: AnalysisModule],
		modules: [String: Module],
		allowErrors: Bool
	) {
		self.compilationUnit = compilationUnit
		self.mode = mode
		self.analyses = analyses
		self.modules = modules
		self.allowErrors = allowErrors
	}

	func run() async throws -> CompilationResult {
		let sourceFiles = try compilationUnit.files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).map {
			try SourceFile(path: $0.path, text: String(contentsOf: $0, encoding: .utf8))
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
		).compile(mode: mode, allowErrors: allowErrors)

		return CompilationResult(module: module, analysis: analysisModule)
	}
}
