//
//  DictionaryAnalysisTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/22/24.
//

import Testing
import TalkTalkAnalysis

struct DictionaryAnalysisTests: AnalysisTest {
	@Test("Works with array literal") func arrayLiteral() async throws {
		let result = try await ast("""
		var a = []
		""").cast(AnalyzedVarDecl.self).valueAnalyzed!

		let instance = InstanceValueType(ofType: .struct("Array"), boundGenericTypes: ["Element": TypeID(.placeholder)])
		#expect(result.typeAnalyzed == .instance(instance))
	}
}
