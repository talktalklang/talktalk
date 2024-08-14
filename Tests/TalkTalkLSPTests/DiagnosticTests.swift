//
//  DiagnosticTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//
import Testing
import TalkTalkAnalysis
import TalkTalkLSP

@MainActor
struct DiagnosticTests {
	@Test("Error on trying to instantiate bad struct") func gets() throws {
		let source = """
		var a = Nope()
		"""

		let diagnostics = try SourceFileAnalyzer.diagnostics(text: source, environment: .init())
		#expect(!diagnostics.isEmpty)
	}
}
