//
//  ProtocolTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/15/24.
//

import TalkTalkAnalysis
import Testing
import TypeChecker

struct ProtocolTests: AnalysisTest {
	@Test("Validates conformance (method)") func validatesConformanceMethod() async throws {
		let ast = try await asts("""
		protocol Greetable {
			func greet() -> String
		}

		struct Person: Greetable {}
		""")

		let errors = ast[1].cast(AnalyzedStructDecl.self).collectErrors()
		#expect(errors.count == 1)
		#expect(errors[0].message.contains("Person does not conform to Greetable"))
	}

	@Test("Validates conformance (property)") func validatesConformanceProperty() async throws {
		let ast = try await asts("""
		protocol Greetable {
			var name: String
		}

		struct Person: Greetable {}
		""")

		let errors = ast[1].cast(AnalyzedStructDecl.self).collectErrors()
		#expect(errors.count == 1)
		#expect(errors[0].message.contains("Person does not conform to Greetable"))
	}
}
