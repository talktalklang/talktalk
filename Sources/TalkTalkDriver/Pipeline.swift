//
//  Pipeline.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import TalkTalkAnalysis
import TalkTalkCompiler
import TalkTalkBytecode
import TalkTalkSyntax

struct Pipeline {
	let compilationUnit: CompilationUnit

	func run() throws -> CompilationResult {
		let sourceFiles = try compilationUnit.files.map {
			try SourceFile(path: $0.path, text: String(contentsOf: $0, encoding: .utf8))
		}

		let parsedSourceFiles = sourceFiles.map {
			ParsedSourceFile(path: $0.path, syntax: Parser.parse($0.text))
		}

		let analysisModule = try ModuleAnalyzer(
			name: compilationUnit.name,
			files: parsedSourceFiles,
			moduleEnvironment: [:]
		).analyze()

		let module = try ModuleCompiler(
			name: compilationUnit.name,
			analysisModule: analysisModule,
			moduleEnvironment: [:]
		).compile(mode: .module)

		return CompilationResult(module: module, analysis: analysisModule)
	}
}
