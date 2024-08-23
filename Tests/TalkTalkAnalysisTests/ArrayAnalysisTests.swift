//
//  ArrayAnalysisTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/20/24.
//

import Testing
import TalkTalkAnalysis

struct ArrayAnalysisTests: AnalysisTest {
	@Test("Works with array literal") func arrayLiteral() async throws {
		let result = try await ast("""
		var a = []
		""")
			.cast(AnalyzedVarDecl.self).valueAnalyzed!

		let instance = InstanceValueType(ofType: .struct("Array"), boundGenericTypes: ["Element": TypeID(.placeholder)])
		#expect(result.typeAnalyzed == .instance(instance))
	}

	@Test("Types array literal") func arrayLiteralTyped() async throws {
		let result = try await ast("""
		var a = [1,2,3]
		""")
			.cast(AnalyzedVarDecl.self).valueAnalyzed!

		guard case let .instance(instance) = result.typeAnalyzed else {
			#expect(Bool(false), "did not get instance"); return
		}

		#expect(instance.ofType == .struct("Array"))
		#expect(instance.boundGenericTypes["Element"]?.current == .int)
	}

	@Test("Types array literal") func arrayLiteralMixedTyped() async throws {
		let result = try await ast("""
		var a = ["fizz"]
		""")
			.cast(AnalyzedVarDecl.self).valueAnalyzed!

		guard case let .instance(instance) = result.typeAnalyzed else {
			#expect(Bool(false), "did not get instance"); return
		}

		#expect(instance.ofType == .struct("Array"))
		#expect(instance.boundGenericTypes["Element"]?.current == .instance(.struct("String")))
	}

	@Test("Types array subscript") func arraySubscript() async throws {
		let result1 = try await ast("""
		[123][0]
		""")
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedSubscriptExpr.self)

		#expect(result1.typeAnalyzed == .int)

		let result2 = try await ast("""
		["foo"][0]
		""")
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedSubscriptExpr.self)

		#expect(result2.typeAnalyzed == .instance(.struct("String")))
	}
}
