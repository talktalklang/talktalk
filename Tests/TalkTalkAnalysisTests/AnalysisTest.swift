//
//  AnalysisTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

import TalkTalkCore
import TalkTalkSyntax
import TalkTalkAnalysis

public protocol AnalysisTest {}

public extension AnalysisTest {
	func ast(_ string: String) async throws -> any AnalyzedSyntax {
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

		let analyzer = ModuleAnalyzer(
			name: "ErrorTests",
			files: [.tmp(string)],
			moduleEnvironment: ["Standard": stdlib],
			importedModules: [stdlib]
		)

		let syntax = try analyzer.analyze().analyzedFiles[0].syntax
		return syntax.last!
	}
}
