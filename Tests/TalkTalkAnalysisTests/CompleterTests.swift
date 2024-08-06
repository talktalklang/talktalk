//
//  CompleterTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//

import TalkTalkAnalysis
import TalkTalkSyntax
import Testing

actor CompleterTests {
	func complete(_ string: String) -> Completer {
		let analyzed = try! Analyzer.analyze(Parser.parse(string))
		let main = (analyzed as! AnalyzedFuncExpr)
		return Completer(exprs: [main])
	}

	@Test("Completes locals") func locals() {
		let completer = complete("""
		person = "Pat"
		pet = "dog"
		cat = "kitty"
		p
		""")

		#expect(completer.completions(at: [4, 1] == [
			"person",
			"pet"
		]))
	}
}
