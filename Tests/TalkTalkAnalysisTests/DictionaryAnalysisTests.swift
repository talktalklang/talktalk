//
//  DictionaryAnalysisTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/22/24.
//

import Testing
import TalkTalkAnalysis

struct DictionaryAnalysisTests: AnalysisTest {
	@Test("Basic") func basic() async throws {
		let result = try await ast("""
		[:]
		""").cast(AnalyzedExprStmt.self).exprAnalyzed

		let instance = InstanceValueType(ofType: .struct("Dictionary"), boundGenericTypes: ["Key": TypeID(.placeholder), "Value": TypeID(.placeholder)])
		#expect(result.typeAnalyzed == .instance(instance))
	}

	@Test("Basic") func types() async throws {
		let result = try await ast("""
		["foo": 123]
		""").cast(AnalyzedExprStmt.self).exprAnalyzed

		let instance = InstanceValueType(
			ofType: .struct("Dictionary"),
			boundGenericTypes: [
				"Key": .instance(.struct("String")),
				"Value": .int
			]
		)
		#expect(result.typeAnalyzed == .instance(instance))
	}
}
