//
//  HTMLHighlighterTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/22/24.
//

@testable import TalkTalkLSP
import TalkTalkSyntax
import Testing

@MainActor
struct HTMLHighlighterTests {
	func highlight(_ string: String) -> String {
		try! HTMLHighlighter(input: .init(path: "string", text: string)).highlight()
	}

	@Test("Highlights an int") func int() {
		#expect(highlight("123") == """
		<span class="number">123</span>
		""")
	}

	@Test("Highlights a keyword") func varA() {
		#expect(highlight("var a") == """
		<span class="keyword">var</span> a
		""")
	}

	@Test("Highlights a keyword with incomplete rest") func keywordIncomplete() {
		#expect(highlight(#"var a = "abc "#) == """
		<span class="keyword">var</span> a = <span class="string">"abc </span>
		""")
	}
}
