//
//  PatternTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/29/24.
//

import TalkTalkCore
import Testing

struct PatternTests {
	@Test("Can parse a let pattern") func letPattern() throws {
		let parsed = try Parser.parse(
			"""
			if let foo {}
			"""
		)

		let pattern = parsed[0]
			.cast(IfStmtSyntax.self).condition
			.cast(LetPatternSyntax.self)

		#expect(pattern.name.lexeme == "foo")
	}
}
