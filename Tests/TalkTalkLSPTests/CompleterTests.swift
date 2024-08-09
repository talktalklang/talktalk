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
	func complete(_ string: String) -> Completer {
		return Completer(source: string)
	}

	@Test("Completes locals") func locals() throws {
		let completer = complete("""
		person = "Pat"
		pet = "dog"

		func nope() {
			part = "nope"
		}

		cat = "kitty"
		p
		""")

		try #expect(completer.completions(at: .init(line: 8, character: 1)).sorted() == [
			CompletionItem(label: "person", kind: .variable),
			CompletionItem(label: "pet", kind: .variable)
		].sorted())
	}
}
