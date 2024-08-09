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
	func analyze(name: String, moduleEnvironment: [String: AnalysisModule] = [:], _ files: ParsedSourceFile...) -> AnalysisModule {
		try! ModuleAnalyzer(name: name, files: files, moduleEnvironment: moduleEnvironment).analyze()
	}

	@Test("Analyzes module functions") func basic() throws {
		let analysisModule = analyze(
			name: "A",
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

		#expect(analysisModule.name == "A")
		#expect(analysisModule.functions.count == 3)

		// First make sure we can get a super basic function with no dependencies
		let bar = try #require(analysisModule.moduleFunction(named: "bar"))
		guard case let .function(barName, barReturnType, params, captures) = bar.type else {
			#expect(Bool(false), "bar type was not a function")
			return
		}

		#expect(barName == "bar")
		#expect(barReturnType == .int)
		#expect(params.isEmpty)
		#expect(captures.isEmpty)

		// Next make sure we can get a function that calls another function that was defined after it
		let foo = try #require(analysisModule.moduleFunction(named: "foo"))
		guard case let .function(fooName, fooReturnType, params, captures) = foo.type else {
			#expect(Bool(false), "foo type was not a function")
			return
		}

		#expect(fooName == "foo")
		#expect(fooReturnType == .int)
		#expect(params.isEmpty)
		#expect(captures.isEmpty)
	}

	@Test("Analyzes module global values") func globalValues() throws {
		let analysisModule = analyze(
			name: "A",
			.tmp("""
			func fizz() {}

			func foo() {
				bar
			}
			"""),
			.tmp("""
			bar = 123
			""")
		)

		#expect(analysisModule.name == "A")
		#expect(analysisModule.values.count == 1)
		#expect(analysisModule.functions.count == 2)

		// First make sure we can get a value
		let bar = try #require(analysisModule.moduleValue(named: "bar"))
		#expect(bar.type == .int)

		// Next make sure we can type a function that uses a module global
		let foo = try #require(analysisModule.moduleFunction(named: "foo"))
		guard case let .function(fooName, fooReturnType, params, captures) = foo.type else {
			#expect(Bool(false), "foo type was not a function")
			return
		}

		#expect(fooName == "foo")
		#expect(fooReturnType == .int)
		#expect(params.isEmpty)
		#expect(captures.isEmpty)
	}

	@Test("Analyzes module function imports") func importing() throws {
		let moduleA = analyze(name: "A", .tmp("func foo() { 123 }"))
		let moduleB = analyze(name: "B", moduleEnvironment: ["A": moduleA], .tmp("""
		import A

		func bar() {
			foo()
		}
		"""))

		let bar = try #require(moduleB.moduleFunction(named: "bar"))
		guard case let .function(name, returnType, params, captures) = bar.type else {
			#expect(Bool(false), "bar type was not a function")
			return
		}

		#expect(name == "bar")
		#expect(returnType == .int)
		#expect(params.isEmpty)
		#expect(captures.isEmpty)
	}

	@Test("Analyzes module structs") func structProperties() throws {
		let module = analyze(name: "A", .tmp("""
		struct Person {
			var age: int

			func getAge() {
				age
			}
		}
		"""))

		let structT = try #require(module.structs["Person"])
		#expect(structT.properties.count == 1)
		#expect(structT.methods.count == 1)
	}
}
