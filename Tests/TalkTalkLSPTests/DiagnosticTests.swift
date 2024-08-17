//
//  DiagnosticTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//
import TalkTalkAnalysis
import TalkTalkLSP
import TalkTalkDriver
import Testing

@MainActor
struct DiagnosticTests {
	@Test("Error on trying to instantiate bad struct") func gets() throws {
		let analyzer = ModuleAnalyzer(name: "Testing", files: ["var a = Nope()"], moduleEnvironment: [:], importedModules: [])

		let module = try analyzer.analyze()
		try #expect(!module.collectErrors().isEmpty)
	}

	@Test("Knows about stdlib") func stdlib() async throws {
		let stdlib = try await StandardLibrary.compile()

		let analyzer = ModuleAnalyzer(
			name: "Testing",
			files: ["var array = Array<int>()"],
			moduleEnvironment: [:],
			importedModules: [stdlib.analysis]
		)

		let module = try analyzer.analyze()
		let errors = try module.collectErrors()
		print(errors)
		print()
		#expect(errors.isEmpty)
	}
}
