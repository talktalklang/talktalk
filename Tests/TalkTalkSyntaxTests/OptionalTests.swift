//
//  OptionalTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/17/24.
//

import TalkTalkSyntax
import Testing

struct OptionalsTests {
	@Test("Can lex a question mark") func lexin() throws {
		let tokens = Lexer.collect(
			"""
			foo?
			"""
		)

		#expect(tokens.map(\.kind) == [
			.identifier,
			.questionMark,
			.eof,
		])
	}

	@Test("Can parse an optional") func parsin() throws {
		let parsed = try Parser.parse(
			"""
			var foo: int?
			var bar: String?
			"""
		)

		let syntax1 = parsed[0].cast(VarDeclSyntax.self).typeExpr!
		let syntax2 = parsed[1].cast(VarDeclSyntax.self).typeExpr!

		#expect(syntax1.isOptional)
		#expect(syntax2.isOptional)
	}
}
