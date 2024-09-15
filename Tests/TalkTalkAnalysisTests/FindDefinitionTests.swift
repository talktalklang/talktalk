//
//  FindDefinitionTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

import TalkTalkAnalysis
import TalkTalkSyntax
import Testing

struct FindDefinitionTests {
	func analyze(
		moduleEnvironment: [String: AnalysisModule] = [:],
		_ files: ParsedSourceFile...
	) throws -> AnalysisModule {
		try ModuleAnalyzer(
			name: "SyntaxTests",
			files: files,
			moduleEnvironment: moduleEnvironment,
			importedModules: []
		).analyze()
	}

	@Test("Find method definition") func methodDef() throws {
		let module = try analyze(
			moduleEnvironment: [:],
			.tmp("""
			struct Person {
				func greet() {
					print("sup")
				}
			}

			var person = Person()
			person.greet()

			""", "person.talk")
		)

		let found = module.findSymbol(line: 7, column: 9, path: "person.talk")!.cast(AnalyzedMemberExpr.self)
		let node = try #require(found)
		#expect(node.receiverAnalyzed.cast(AnalyzedVarExpr.self).name == "person")
		#expect(node.property == "greet")
		#expect(node.location.line == 7)

		let definition = node.definition()!
		#expect(definition.location.line == 1)
		#expect(definition.location.start.column == 6)
	}

	@Test("Find property definition") func propertyDef() throws {
		let module = try analyze(
			moduleEnvironment: [:],
			.tmp("""
			struct Person {
				var name: int
			}

			var person = Person()
			person.name
			""", "person.talk")
		)

		let found = module.findSymbol(line: 5, column: 9, path: "person.talk")!
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedMemberExpr.self)
		let node = try #require(found)
		#expect(node.receiverAnalyzed.cast(AnalyzedVarExpr.self).name == "person")
		#expect(node.property == "name")
		#expect(node.location.line == 5)

		let definition = node.definition()!
		#expect(definition.location.line == 1)
		#expect(definition.location.start.column == 5)
	}

	@Test("Find type definition") func typeDef() throws {
		let module = try analyze(
			moduleEnvironment: [:],
			.tmp("""
			struct Person {
				var name: int
			}

			var person = Person()
			person.name
			""", "person.talk")
		)

		let found = module.findSymbol(line: 4, column: 15, path: "person.talk")!
			.cast(AnalyzedVarExpr.self)
		let node = try #require(found)
		#expect(node.name == "Person")
		#expect(node.location.line == 4)

		let definition = node.definition()!
		#expect(definition.location.line == 0)
		#expect(definition.location.start.column == 7)
	}

	@Test("Find var definition") func varDef() throws {
		let module = try analyze(
			moduleEnvironment: [:],
			.tmp("""
			var age = 123
			age

			""", "person.talk")
		)

		let found = module.findSymbol(line: 1, column: 1, path: "person.talk")!
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedVarExpr.self)
		let node = try #require(found)
		#expect(node.name == "age")
		#expect(node.location.line == 1)

		let definition = node.definition()!
		#expect(definition.location.line == 0)
		#expect(definition.location.start.column == 4)
	}

	@Test("Find var definition in call") func callVarDef() throws {
		let module = try analyze(
			moduleEnvironment: [:],
			.tmp("""
			struct Person {
				var name: String
			}

			var person = Person()
			person.name
			""", "person.talk")
		)

		let found = module.findSymbol(line: 5, column: 3, path: "person.talk")!
			.cast(AnalyzedVarExpr.self)
		let node = try #require(found)
		#expect(node.name == "person")
		#expect(node.location.line == 5)

		let definition = node.definition()!
		#expect(definition.location.line == 4)
		#expect(definition.location.start.column == 4)
	}

	@Test("Find property inside method") func propInMethod() throws {
		let module = try analyze(
			moduleEnvironment: [:],
			.tmp("""
			struct Person {
				var name: int

				func greet() {
					self.name
				}
			}
			""", "person.talk")
		)

		let found = module.findSymbol(line: 4, column: 8, path: "person.talk")!
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.as(AnalyzedMemberExpr.self)
		let node = try #require(found)
		#expect(node.property == "name")
		#expect(node.location.line == 4)

		let definition = node.definition()!
		#expect(definition.location.line == 1)
		#expect(definition.location.start.column == 5)
	}
}
