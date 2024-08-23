//
//  CompilerTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/21/24.
//

import Testing
import TalkTalkCore
import TalkTalkCompiler
import TalkTalkSyntax
import TalkTalkAnalysis
import TalkTalkBytecode

protocol CompilerTest {}

extension CompilerTest {
	func compile(_ strings: String...) throws -> Module {
		let stdlib = try ModuleAnalyzer(
			name: "Standard",
			files: Set(Library.files(for: Library.standardLibraryURL).map {
				try ParsedSourceFile(
					path: $0.path,
					syntax: Parser.parse(
						SourceFile(
							path: $0.path,
							text: String(contentsOf: $0, encoding: .utf8)
						)
					)
				)
			}),
			moduleEnvironment: [:],
			importedModules: []
		).analyze()

		let stdlibModule = try ModuleCompiler(name: "Standard", analysisModule: stdlib).compile(mode: .module)

		let analysisModule = try ModuleAnalyzer(
			name: "E2E",
			files: Set(strings.enumerated().map { .tmp($1, "\($0).tlk") }),
			moduleEnvironment: ["Standard": stdlib],
			importedModules: [stdlib]
		).analyze()
		let compiler = ModuleCompiler(name: "E2E", analysisModule: analysisModule, moduleEnvironment: ["Standard": stdlibModule])
		return try compiler.compile(mode: .executable)
	}

	func compile(
		name: String,
		_ files: [ParsedSourceFile],
		analysisEnvironment: [String: AnalysisModule] = [:],
		moduleEnvironment: [String: Module] = [:]
	) throws -> (Module, AnalysisModule) {
		let analysis = moduleEnvironment.reduce(into: [:]) { res, tup in res[tup.key] = analysisEnvironment[tup.key] }
		let analyzed = try ModuleAnalyzer(
			name: name,
			files: Set(files),
			moduleEnvironment: analysis,
			importedModules: Array(analysisEnvironment.values)
		).analyze()

		let module = try ModuleCompiler(
			name: name,
			analysisModule: analyzed,
			moduleEnvironment: moduleEnvironment
		).compile(mode: .executable)

		return (module, analyzed)
	}
}
