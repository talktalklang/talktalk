//
//  AnalysisTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

import TalkTalkAnalysis
import TalkTalkCore
import TalkTalkSyntax

extension InstanceValueType {
	// Define this helper here so that we don't have to be so verbose in tests. We want to be verbose in the implementation tho.
	public static func `struct`(_ name: String, _ boundGenericTypes: [String: TypeID] = [:]) -> InstanceValueType {
		InstanceValueType(ofType: .struct(name), boundGenericTypes: boundGenericTypes)
	}
}

public protocol AnalysisTest {}

public extension AnalysisTest {
	func analyze(_ string: String) async throws -> AnalysisModule {
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
			name: "AnalysisTest",
			files: [.tmp(string, "Analysis.tlk")],
			moduleEnvironment: ["Standard": stdlib],
			importedModules: [stdlib]
		)

		return try analyzer.analyze()
	}

	func ast(_ string: String) async throws -> any AnalyzedSyntax {
		let syntax = try await analyze(string).analyzedFiles[0].syntax
		return syntax.last!
	}
}
