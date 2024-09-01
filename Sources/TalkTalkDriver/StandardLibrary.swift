//
//  StandardLibrary.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import TalkTalkCompiler
import TalkTalkAnalysis
import TalkTalkCore
import TalkTalkSyntax

public enum StandardLibrary {
	public static func compile(allowErrors: Bool = false) async throws -> CompilationResult {
		let analyzer = ModuleAnalyzer(
			name: "Standard",
			files: Library.standard.paths.map {
				let url = Library.standard.location.appending(path: $0)
				let source = try! String(contentsOf: url, encoding: .utf8)
				let parsed = try! Parser.parse(.init(path: url.path, text: source))
				return ParsedSourceFile(path: url.path, syntax: parsed)
			},
			moduleEnvironment: [:],
			importedModules: []
		)

		let analyzed = try analyzer.analyze()

		let compiler = ModuleCompiler(name: "Standard", analysisModule: analyzed)
		let module = try compiler.compile(mode: .module)

		return CompilationResult(module: module, analysis: analyzed)
	}
}
