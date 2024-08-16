//
//  CompleterTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//

@testable import TalkTalkLSP
import TalkTalkSyntax
import TalkTalkAnalysis
import Testing

@MainActor
struct CompleterTests {
	func complete(_ string: String) async -> Completer {
		return await Completer(source: string)
	}

	@Test("Completes locals") func locals() async throws {
		let completer = await complete("""
		person = "Pat"
		pet = "dog"

		func nope() {
			part = "nope"
		}

		cat = "kitty"
		p
		""")

		try await #expect(completer.completions(
			from: .init(
				position: .init(line: 8, character: 1),
				textDocument: .init(uri: "", version: nil, text: nil),
				context: .init(triggerKind: .character, triggerCharacter: nil)
			)
		).sorted() == [
			CompletionItem(label: "person", kind: .variable),
			CompletionItem(label: "pet", kind: .variable),
			CompletionItem(label: "print", kind: .function)
		].sorted())
	}

	@Test("Completes members") func members() async throws {
		let completer = await complete("""
		struct Person {
			var age: int
			var code: int

			func greet() {}
		}

		var person = Person()
		person.
		""")

		try await #expect(completer.completions(
			from: .init(
				position: .init(line: 8, character: 1),
				textDocument: .init(uri: "", version: nil, text: nil),
				context: .init(triggerKind: .character, triggerCharacter: ".")
			)
		).sorted() == [
			CompletionItem(label: "age", kind: .property),
			CompletionItem(label: "code", kind: .property),
			CompletionItem(label: "greet", kind: .method),
		].sorted())
	}
}
