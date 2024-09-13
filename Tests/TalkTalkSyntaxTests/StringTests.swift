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

	@Test("Lexing interpolated string") func interpolateLex() throws {
		let tokens = Lexer.collect(#"""
		"foo \("bar") fizz"
		"""#)

		#expect(tokens.map(\.kind) == [
			.string,
			.interpolationStart,
			.string,
			.interpolationEnd,
			.string,
			.eof
		])
	}

	@Test("Lexing nested interpolated string") func interpolateNestedLex() throws {
		let tokens = Lexer.collect(#"""
		"foo \("fizz \("buzz")") bar"
		"""#)

		#expect(tokens.map(\.kind) == [
			.string,
			.interpolationStart,
			.string,
			.interpolationStart,
			.string,
			.interpolationEnd,
			.string,
			.interpolationEnd,
			.string,
			.eof
		])
	}

	@Test("Can have interpolated string") func interpolated() throws {
		let parsed = try Parser.parse(#" "foo \("bar")" "#)[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(InterpolatedStringExprSyntax.self)

		#expect(parsed.segments.count == 2)
	}
}
