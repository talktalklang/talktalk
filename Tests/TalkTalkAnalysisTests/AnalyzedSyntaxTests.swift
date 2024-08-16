//
//  AnalyzedSyntaxTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

import Testing
import TalkTalkSyntax
import TalkTalkAnalysis

struct AnalyzedSyntaxTests {
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
			"""
			struct Person {
				func greet() {
					print("sup")
				}
			}

			var person = Person()
			person.greet()
			"""
		)

		let found = module.findSymbol(line: 7, column: 9, path: "<literal>")!.cast(AnalyzedMemberExpr.self)
		let node = try #require(found)
		#expect(node.receiverAnalyzed.cast(AnalyzedVarExpr.self).name == "person")
		#expect(node.property == "greet")
		#expect(node.location.line == 7)

		let definition = node.definition()!
		#expect(definition.token.line == 1)
		#expect(definition.token.column == 6)
	}

	@Test("Find property definition") func propertyDef() throws {
		let module = try analyze(
			moduleEnvironment: [:],
			"""
			struct Person {
				var name: String
			}

			var person = Person()
			person.name
			"""
		)

		let found = module.findSymbol(line: 5, column: 9, path: "<literal>")!
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedMemberExpr.self)
		let node = try #require(found)
		#expect(node.receiverAnalyzed.cast(AnalyzedVarExpr.self).name == "person")
		#expect(node.property == "name")
		#expect(node.location.line == 5)

		let definition = node.definition()!
		print(definition)
		#expect(definition.token.line == 1)
		#expect(definition.token.column == 5)
	}

	@Test("Find var definition") func varDef() throws {
		let module = try analyze(
			moduleEnvironment: [:],
			"""
			var age = 123
			age
			"""
		)

		let found = module.findSymbol(line: 1, column: 1, path: "<literal>")!
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedVarExpr.self)
		let node = try #require(found)
		#expect(node.name == "age")
		#expect(node.location.line == 1)

		let definition = node.definition()!
		#expect(definition.token.line == 0)
		#expect(definition.token.column == 10)
	}
}
