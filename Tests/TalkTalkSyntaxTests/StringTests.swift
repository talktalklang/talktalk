//
//  StringTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/12/24.
//

import Testing
@testable import TalkTalkSyntax

struct StringTests {
	@Test("Basic") func basic() throws {
		let parsed = try Parser.parse("""
		"sup"
		""")[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(LiteralExprSyntax.self)

		#expect(parsed.value == .string("sup"))
	}

	@Test("Escape quote") func escapeQuote() throws {
		let parsed = try Parser.parse(#" "\"" "#)[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(LiteralExprSyntax.self)

		#expect(parsed.value == .string(#"""#))
	}

	@Test("newline") func newline() throws {
		let parsed = try Parser.parse(#" "foo\nbar" "#)[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(LiteralExprSyntax.self)

		#expect(parsed.value == .string("""
		foo
		bar
		"""))
	}

	@Test("tab") func tab() throws {
		let parsed = try Parser.parse(#" "foo\tbar" "#)[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(LiteralExprSyntax.self)

		#expect(parsed.value == .string("""
		foo	bar
		"""))
	}

	@Test("Slash") func slash() throws {
		let parsed = try Parser.parse(#" "\\" "#)[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(LiteralExprSyntax.self)

		#expect(parsed.value == .string(#"\"#))
	}

	@Test("Throws if it's not a valid escape sequence") func throwsIfInvalid() throws {
		#expect(throws: StringParser<String>.StringError.self) {
			try StringParser.parse(#""\o""#)
		}
	}
}
