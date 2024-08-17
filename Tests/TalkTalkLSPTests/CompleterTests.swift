//
//  CompleterTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//

import TalkTalkAnalysis
@testable import TalkTalkLSP
import TalkTalkDriver
import TalkTalkSyntax
import Testing

@MainActor
struct CompleterTests {
	func complete(_ request: Completion.Request, in string: String) async throws -> Set<Completion.Item> {

		let stdlib = try await StandardLibrary.compile()

		var analyzer = ModuleAnalyzer(
			name: "Testing",
			files: [],
			moduleEnvironment: [:],
			importedModules: [stdlib.analysis]
		)

		let module = try analyzer.addFile(
			.init(
				path: "test",
				syntax: Parser.parse(
					.init(
						path: "test",
						text: string
					), allowErrors: true
				)
			)
		)

		return module.completions(for: request)
	}

	@Test("Completes locals") func locals() async throws {
		let results = try await complete(
			.init(
				documentURI: "test",
				line: 8,
				column: 1
			), in: """
			let person = "Pat"
			let pet = "dog"

			func nope() {
				part = "nope"
			}

			cat = "kitty"
			p
			"""
		)

		#expect(results.sorted() == [
			Completion.Item(value: "person", kind: .variable),
			Completion.Item(value: "pet", kind: .variable),
			Completion.Item(value: "print", kind: .function),
		].sorted())
	}

	@Test("Completes members") func members() async throws {
		let results = try await complete(
			.init(
				documentURI: "test", line: 8, column: 1, trigger: .character(".")
			), in: """
			struct Person {
				var age: int
				var code: int

				func greet() {}
			}

			var person = Person()
			person.
			"""
		)

		#expect(results.sorted() == [
			Completion.Item(value: "age", kind: .property),
			Completion.Item(value: "code", kind: .property),
			Completion.Item(value: "greet", kind: .method),
		].sorted())
	}

	@Test("Completes types") func types() async throws {
		let results = try await complete(
			.init(
				documentURI: "test",
				line: 1,
				column: 1,
				trigger: nil
			), in: """
			struct Person {}
			P
			"""
		)

		#expect(results.sorted() == [
			Completion.Item(value: "Person", kind: .type),
		].sorted())
	}

	@Test("Completes stdlib types") func stdlibtypes() async throws {
		let results = try await complete(
			.init(
				documentURI: "test",
				line: 0,
				column: 1,
				trigger: nil
			), in: """
			A
			"""
		)

		#expect(results.sorted() == [
			Completion.Item(value: "Array", kind: .type),
		].sorted())
	}
}
