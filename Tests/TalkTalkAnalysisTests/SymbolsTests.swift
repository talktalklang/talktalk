//
//  SymbolsTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/21/24.
//

import Testing
import TalkTalkAnalysis

struct SymbolsTests: AnalysisTest {
	@Test("Generates symbol for top level function") func topLevelFunction() async throws {
		let analysis = try await analyze("func foo() {}")

		#expect(analysis.symbols.count == 2)
		#expect(analysis.symbols[.function("AnalysisTest", "Analysis.tlk", [])] != nil)
		#expect(analysis.symbols[.function("AnalysisTest", "foo", [])] != nil)
	}

	@Test("Generates symbol for top level var") func topLevelVar() async throws {
		let analysis = try await analyze("var foo = 123")

		#expect(analysis.symbols[.function("AnalysisTest", "Analysis.tlk", [])] != nil)
		#expect(analysis.symbols[.value("AnalysisTest", "foo")] != nil)
	}

	@Test("Generates symbol for top level let") func topLevelLet() async throws {
		let analysis = try await analyze("let foo = 123")

		#expect(analysis.symbols[.function("AnalysisTest", "Analysis.tlk", [])] != nil)
		#expect(analysis.symbols[.value("AnalysisTest", "foo")] != nil)
	}

	@Test("Generates symbol for anonymous functions") func anonFunc() async throws {
		let analysis = try await analyze("""
		func() {
			func() { 123 }
		}
		""")

		#expect(analysis.symbols.count == 3)
		#expect(analysis.symbols[.function("AnalysisTest", "Analysis.tlk", [])] != nil)
		#expect(analysis.symbols[.function("AnalysisTest", "_fn__25", [], namespace: ["_fn__26"])] != nil)
		#expect(analysis.symbols[.function("AnalysisTest", "_fn__26", [])] != nil)
	}

	@Test("Generates symbol for inner func") func innerFunc() async throws {
		let analysis = try await analyze("""
		func foo() {
			func bar() {
			}
		}
		""")

		#expect(analysis.symbols[.function("AnalysisTest", "Analysis.tlk", [])] != nil)
		#expect(analysis.symbols[.function("AnalysisTest", "foo", [])] != nil)
		#expect(analysis.symbols[.function("AnalysisTest", "bar", [], namespace: ["foo"])] != nil)
	}

	@Test("Handles inner func name clashes") func innerFuncNameClashes() async throws {
		let analysis = try await analyze("""
		func foo() {
			func bar() {}
		}

		func fizz() {
			func bar() {}
		}
		""")

		#expect(analysis.symbols.count == 5)
		#expect(analysis.symbols[.function("AnalysisTest", "foo", [])] != nil)
		#expect(analysis.symbols[.function("AnalysisTest", "bar", [], namespace: ["foo"])] != nil)
		#expect(analysis.symbols[.function("AnalysisTest", "fizz", [])] != nil)
		#expect(analysis.symbols[.function("AnalysisTest", "bar", [], namespace: ["fizz"])] != nil)
	}

	@Test("Generates symbol for struct") func structs() async throws {
		let analysis = try await analyze("""
		struct Person {}
		""")

		#expect(analysis.symbols.count == 3)
		#expect(analysis.symbols[.value("AnalysisTest", "self", namespace: ["Person"])] != nil)
		#expect(analysis.symbols[.struct("AnalysisTest", "Person")] != nil)
	}

	@Test("Generates a symbol for methods") func methods() async throws {
		let analysis = try await analyze("""
		struct Person {
			func greet(name) {}
		}
		""")

		#expect(analysis.symbols.count == 4)
		#expect(analysis.symbols[.value("AnalysisTest", "self", namespace: ["Person"])] != nil)
		#expect(analysis.symbols[.method("AnalysisTest", "Person", "greet", ["name"])] != nil)
		#expect(analysis.symbols[.struct("AnalysisTest", "Person")] != nil)
	}

	@Test("Does not generate a method symbol for free bound methods") func boundMethods() async throws {
		let analysis = try await analyze("""
		struct Person {
			func greet(name) {}
		}

		let method = Person().greet
		method()
		""")

		#expect(analysis.symbols.count == 5)

		print(analysis.symbols)
		print()

		#expect(analysis.symbols[.value("AnalysisTest", "method")] != nil)
		#expect(analysis.symbols[.value("AnalysisTest", "self", namespace: ["Person"])] != nil)
		#expect(analysis.symbols[.method("AnalysisTest", "Person", "greet", ["name"])] != nil)
		#expect(analysis.symbols[.struct("AnalysisTest", "Person")] != nil)
	}

	@Test("Generates a symbol for properties") func properties() async throws {
		let analysis = try await analyze("""
		struct Person {
			var age: int
		}
		""")

		#expect(analysis.symbols.count == 4)
		#expect(analysis.symbols[.function("AnalysisTest", "Analysis.tlk", [])] != nil)
		#expect(analysis.symbols[.value("AnalysisTest", "self", namespace: ["Person"])] != nil)
		#expect(analysis.symbols[.property("AnalysisTest", "Person", "age", namespace: ["Person"])] != nil)
		#expect(analysis.symbols[.struct("AnalysisTest", "Person")] != nil)
	}

	@Test("Does not create a symbol for local varialbes in functions") func locals() async throws {
		let analysis = try await analyze("""
		func() {
			var a = 123
		}
		""")

		#expect(analysis.symbols.count == 2)
		#expect(analysis.symbols[.function("AnalysisTest", "Analysis.tlk", [])] != nil)
		#expect(analysis.symbols[.function("AnalysisTest", "_fn__23", [])] != nil)
	}

	@Test("Does not create a symbol for local variables in methods") func propsVsValues() async throws {
		let analysis = try await analyze("""
		struct Person {
			var age: int

			func greet() {
				var newAge = 123 // Should not create a symbol
			}
		}
		""")

		#expect(analysis.symbols.count == 5)
		#expect(analysis.symbols[.property("AnalysisTest", "Person", "age", namespace: ["Person"])] != nil)
		#expect(analysis.symbols[.value("AnalysisTest", "self", namespace: ["Person"])] != nil)
	}
}
