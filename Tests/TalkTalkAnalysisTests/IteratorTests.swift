//
//  IteratorTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/20/24.
//

import TalkTalkAnalysis
import TalkTalkCore
import TalkTalkSyntax
import Testing
@testable import TypeChecker

struct IteratorTests: AnalysisTest {
	@Test("Can analyze a for loop") func forLoop() async throws {
		let ast = try await ast("""
		for i in [1,2,3] {
			print(i)
		}
		""")

		let stmt = ast.cast(AnalyzedForStmt.self)

		#expect(stmt.elementAnalyzed.cast(AnalyzedVarExpr.self).name == "i")
		#expect(stmt.sequenceAnalyzed.cast(AnalyzedArrayLiteralExpr.self).exprsAnalyzed.count == 3)
		#expect(stmt.iteratorSymbol == .method("AnalysisTest", "Array", "makeIterator", []))
	}
}
