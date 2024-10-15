//
//  ArrayAnalysisTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/20/24.
//

import TalkTalkAnalysis
import Testing
import TypeChecker

struct ArrayAnalysisTests: AnalysisTest {
	@Test("Works with array literal") func arrayLiteral() async throws {
		let result = try await ast("""
		var a = []
		a
		""")
		.cast(AnalyzedExprStmt.self).exprAnalyzed

		let instance = try #require(Instance<StructType>.extract(from: result.typeAnalyzed))
		#expect(instance.type.name == "Array")
	}

	@Test("Types array subscript") func subscriptArray() async throws {
		let result1 = try await ast("""
		[123][0]
		""")
		.cast(AnalyzedExprStmt.self).exprAnalyzed
		.cast(AnalyzedSubscriptExpr.self)

		#expect(result1.typeAnalyzed == .base(.int))

		let result2 = try await ast("""
		["foo"][0]
		""")
		.cast(AnalyzedExprStmt.self).exprAnalyzed
		.cast(AnalyzedSubscriptExpr.self)

		#expect(result2.typeAnalyzed == .base(.string))
	}

	@Test("Types array elements when it's a generic property") func typesArrayElementWhenProperty() async throws {
		let ast = try await ast("""
		struct WrapperEntry {}

		struct Wrapper {
			var store: Array<WrapperEntry>

			func get(i) {
				self.store[i]
			}
		}
		""")

		let structDecl = try #require(ast as? AnalyzedStructDecl)
		let funcDecl = try #require(structDecl.bodyAnalyzed.declsAnalyzed.last as? AnalyzedFuncExpr)
		let exprStmt = funcDecl.bodyAnalyzed.stmtsAnalyzed[0].cast(AnalyzedExprStmt.self).exprAnalyzed
		let subscriptExpr = exprStmt.cast(AnalyzedSubscriptExpr.self)

		let instance = try #require(Instance<StructType>.extract(from: subscriptExpr.inferenceType))
		#expect(instance.type.name == "WrapperEntry")
	}
}
