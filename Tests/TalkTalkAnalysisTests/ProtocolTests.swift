//
//  ProtocolTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/15/24.
//

import TalkTalkAnalysis
import TypeChecker
import Testing

struct ProtocolTests: AnalysisTest {
	@Test("Validates conformance") func validatesConformance() async throws {
		let ast = try await asts("""
		protocol Greetable {
			func greet() -> String
		}

		struct Person: Greetable {}
		""")

		let errors = ast[1].cast(AnalyzedStructDecl.self).collectErrors()
		#expect(errors.count == 1)
		#expect(errors[0].message == "Type does not conform to: Greetable. Missing: function(), returns(string)")
	}
}
