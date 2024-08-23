//
//  DictionaryTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/22/24.
//

import Testing
import TalkTalkSyntax

struct DictionaryTests {
	@Test("Basic dictionary") func basic() throws {
		let parsed = try Parser.parse(
			"""
			["foo": "bar", "fizz": "buzz"]
			"""
		)[0].cast(ExprStmtSyntax.self).expr

		let dictionaryLiteral = try #require(parsed as? DictionaryLiteralExprSyntax)
		#expect(dictionaryLiteral.elements.count == 2)

		let first = dictionaryLiteral.elements[0].cast(DictionaryElementExprSyntax.self)
		#expect(first.key.cast(LiteralExprSyntax.self).value == .string("foo"))
		#expect(first.value.cast(LiteralExprSyntax.self).value == .string("bar"))

		let second = dictionaryLiteral.elements[1].cast(DictionaryElementExprSyntax.self)
		#expect(second.key.cast(LiteralExprSyntax.self).value == .string("fizz"))
		#expect(second.value.cast(LiteralExprSyntax.self).value == .string("buzz"))
	}

	@Test("Dictionary literal with subscript") func literalSubscript() throws {
		let parsed = try Parser.parse(
			"""
			["foo": "bar", "fizz": "buzz"]["foo"]
			"""
		)[0].cast(ExprStmtSyntax.self).expr
			.cast(SubscriptExprSyntax.self)
		
		let dictionaryLiteral = try #require(parsed.receiver as? DictionaryLiteralExprSyntax)
		#expect(dictionaryLiteral.elements.count == 2)

		let first = dictionaryLiteral.elements[0].cast(DictionaryElementExprSyntax.self)
		#expect(first.key.cast(LiteralExprSyntax.self).value == .string("foo"))
		#expect(first.value.cast(LiteralExprSyntax.self).value == .string("bar"))

		let second = dictionaryLiteral.elements[1].cast(DictionaryElementExprSyntax.self)
		#expect(second.key.cast(LiteralExprSyntax.self).value == .string("fizz"))
		#expect(second.value.cast(LiteralExprSyntax.self).value == .string("buzz"))

		#expect(parsed.args[0]
			.cast(CallArgument.self).value
			.cast(LiteralExprSyntax.self).value == .string("foo")
		)
	}
}
