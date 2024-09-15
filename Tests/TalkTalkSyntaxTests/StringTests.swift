//
//  StringTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/12/24.
//

@testable import TalkTalkSyntax
import Testing

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
		let parsed = try Parser.parse(#" " foo\tbar" "#)[0]
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
			try StringParser.parse(#""\o""#, context: .normal)
		}
	}

	@Test("Lexing interpolated with no prefix") func interpolateNoPrefix() throws {
		let tokens = Lexer.collect(#"""
		"\("bar") fizz"
		"""#)

		#expect(tokens.map(\.kind) == [
			.string,
			.interpolationStart,
			.string,
			.interpolationEnd,
			.string,
			.eof,
		])
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
			.eof,
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
			.eof,
		])
	}

	@Test("Doesn't crash up on bad interpolation") func badInterpolation() throws {
		#expect(throws: Parser.ParserError.self) {
			try Parser.parse(#" "foo \(" "#)[0]
		}
	}

	@Test("Can parse interpolated string") func interpolated() throws {
		let parsed = try Parser.parse(#" "foo \("bar") " "#)[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(InterpolatedStringExprSyntax.self)

		#expect(parsed.segments.count == 3)
		#expect(parsed.segments[0].description == "string(foo )")
		#expect(parsed.segments[2].description == "string( )")
	}
}
