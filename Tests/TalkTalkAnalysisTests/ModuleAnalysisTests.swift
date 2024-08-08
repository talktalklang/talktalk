//
//  ModuleAnalysisTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import Testing
import TalkTalkAnalysis
import TalkTalkSyntax

actor ModuleAnalysisTests {
	func analyze(_ files: ParsedSourceFile...) -> AnalysisModule {
		try! ModuleAnalyzer(name: "ModuleAnalysisTests", files: files).analyze()
	}

	@Test("Analyzes module") func basic() throws {
		let analysisModule = analyze(
			.tmp("""
			func fizz() {}

			func foo() {
				bar()
			}
			"""),
			.tmp("""
			func bar() {
				123
			}
			""")
		)

		#expect(analysisModule.name == "ModuleAnalysisTests")
		#expect(analysisModule.globals.count == 3)

		// First make sure we can get a super basic function with no dependencies
		let bar = try #require(analysisModule.global(named: "bar"))
		guard case let .function(barName, barReturnType, params, captures) = bar.type else {
			#expect(Bool(false), "bar type was not a function")
			return
		}

		#expect(barName == "bar")
		#expect(barReturnType == .int)
		#expect(params.isEmpty)
		#expect(captures.isEmpty)

		// Next make sure we can get a function that calls another function that was defined after it
		let foo = try #require(analysisModule.global(named: "foo"))
		guard case let .function(fooName, fooReturnType, params, captures) = foo.type else {
			#expect(Bool(false), "foof type was not a function")
			return
		}

		#expect(fooName == "foo")
		#expect(fooReturnType == .int)
		#expect(params.isEmpty)
		#expect(captures.isEmpty)
	}
}
