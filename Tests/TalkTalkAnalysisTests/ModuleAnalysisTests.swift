//
//  ModuleAnalysisTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkAnalysis
import TalkTalkCore
import Testing
import TypeChecker

struct ModuleAnalysisTests {
	func analyzer(
		name: String,
		moduleEnvironment: [String: AnalysisModule] = [:],
		_ files: [ParsedSourceFile]
	) -> ModuleAnalyzer {
		try! ModuleAnalyzer(
			name: name,
			files: files,
			moduleEnvironment: moduleEnvironment,
			importedModules: []
		)
	}

	func analyze(
		name: String,
		moduleEnvironment: [String: AnalysisModule] = [:],
		_ files: ParsedSourceFile...
	) throws -> AnalysisModule {
		try analyzer(
			name: name,
			moduleEnvironment: moduleEnvironment,
			files
		).analyze()
	}

	@Test("Analyzes module functions") func basic() throws {
		let analysisModule = try analyze(
			name: "A",
			.tmp("""
			func fizz() {}

			func foo() {
				bar()
			}
			""", "a"),
			.tmp("""
			func bar() {
				123
			}
			""", "a2")
		)

		#expect(analysisModule.name == "A")
		#expect(analysisModule.moduleFunctions.count == 3)

		// First make sure we can get a super basic function with no dependencies
		let bar = try #require(analysisModule.moduleFunction(named: "bar"))
		#expect(bar.typeID == .function([], .resolved(.base(.int))))

		// Next make sure we can get a function that calls another function that was defined after it
		let foo = try #require(analysisModule.moduleFunction(named: "foo"))
		#expect(foo.typeID == .function([], .resolved(.base(.int))))
	}

	@Test("Analyzes module global values") func globalValues() throws {
		let analysisModule = try analyze(
			name: "A",
			.tmp("""
			func fizz() {}

			func foo() {
				bar
			}
			""", "a"),
			.tmp("""
			let bar = 123
			""", "a2")
		)

		#expect(analysisModule.name == "A")
		#expect(analysisModule.values.count == 1)
		#expect(analysisModule.moduleFunctions.count == 2)

		#expect(analysisModule.values["bar"]?.name == "bar")

		// First make sure we can get a value
		let bar = try #require(analysisModule.moduleValue(named: "bar"))
		#expect(bar.typeID == .base(.int))

		// Next make sure we can type a function that uses a module global
		let foo = try #require(analysisModule.moduleFunction(named: "foo"))
		#expect(foo.typeID == .function([], .resolved(.base(.int))))
	}

	@Test("Analyzes module function imports") func importing() throws {
		let moduleA = try analyze(name: "A", .tmp("func foo() { 123 }", "foo.talk"))
		let moduleB = try analyze(name: "B", moduleEnvironment: ["A": moduleA], .tmp("""
		import A

		func bar() {
			foo()
		}
		""", "a.talk"))

		// Make sure we're actually loading these
		let foo = try #require(moduleA.moduleFunction(named: "foo"))
		#expect(foo.name == "foo")
		#expect(foo.typeID == .function([], .resolved(.base(.int))))

		let bar = try #require(moduleB.moduleFunction(named: "bar"))
		#expect(bar.typeID == .function([], .resolved(.base(.int))))
	}

	@Test("Analyzes module structs") func structProperties() throws {
		let module = try analyze(name: "A", .tmp("""
		struct Person {
			var age: int

			func getAge() {
				age
			}
		}
		""", "person.talk"))

		let structT = try #require(module.structs["Person"])
		#expect(structT.properties.count == 1)
		#expect(structT.methods.count == 2) // add 1 for the synthesized init
	}

	@Test("Analyzes imported module structs") func importStructProperties() throws {
		let moduleA = try analyze(name: "A", .tmp("""
		struct Person {
			var age: int

			init(age: int) {
				self.age = age
			}

			func getAge() {
				age
			}
		}
		""", "person.talk"))

		let moduleB = try analyze(name: "B", moduleEnvironment: ["A": moduleA], .tmp("""
		import A

		let person = Person(age: 123)
		person.age
		""", "person.talk"))

		let person = try #require(moduleB.values["person"])
		let personInstance = try #require(Instance<StructType>.extract(from: person.typeID))
		#expect(personInstance.type.name == "Person")
	}

	@Test("Add file to analyzer") func addFile() throws {
		var analyzer = analyzer(
			name: "A",
			[
				"""
				func fizz() {}

				func foo() {
					bar()
				}
				""",
			]
		)

		var analysisModule = try analyzer.analyze()
		#expect(analysisModule.name == "A")
		#expect(analysisModule.moduleFunctions.count == 2)

		analysisModule = try analyzer.addFile(
			"""
			func bar() {
				123
			}
			"""
		).1

		#expect(analysisModule.name == "A")
		#expect(analysisModule.moduleFunctions.count == 3)
	}
}
