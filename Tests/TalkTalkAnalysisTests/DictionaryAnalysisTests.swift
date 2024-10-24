//
//  DictionaryAnalysisTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/22/24.
//

import TalkTalkAnalysis
import Testing
@testable import TypeChecker

@Suite() struct DictionaryAnalysisTests: AnalysisTest {
	@Test("Basic") func basic() async throws {
		let result = try ast("""
		[:]
		""").cast(AnalyzedExprStmt.self).exprAnalyzed.typeAnalyzed

		let instance = Instance<StructType>.extract(from: result)
		#expect(instance?.type.name == "Dictionary")
	}

	@Test("Types keys/values") func types() async throws {
		let result = try ast("""
		["foo": 123]
		""").cast(AnalyzedExprStmt.self).exprAnalyzed.typeAnalyzed

		let instance = Instance<StructType>.extract(from: result)
		#expect(instance?.type.name == "Dictionary")
		#expect(instance?.relatedType(named: "Key") == .base(.string))
		#expect(instance?.relatedType(named: "Value") == .base(.int))
	}

	@Test("Types subscript") func subscripts() async throws {
		let result = try ast("""
		["foo": 123]["foo"]
		""")
		.cast(AnalyzedExprStmt.self).exprAnalyzed
		.cast(AnalyzedSubscriptExpr.self)

		#expect(result.typeAnalyzed == .optional(.base(.int)))
	}
}
