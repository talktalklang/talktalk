//
//  CaseStatementTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/4/24.
//

import Testing
import TalkTalkSyntax

struct CaseStatementTests {
	@Test("Can lex") func lexin() throws {
		let tokens = Lexer.collect(.tmp("""
		match thing {
		case .foo(fizz):
			true
		case .bar(buzz), .sup:
			false
		}
		"""))

		#expect(tokens.map(\.kind) == [
			.match, .identifier, .leftBrace, .newline,
			.`case`, .dot, .identifier, .leftParen, .identifier, .rightParen, .colon, .newline,
			.true, .newline,
			.`case`, .dot, .identifier, .leftParen, .identifier, .rightParen, .comma, .dot, .identifier, .colon, .newline,
			.false, .newline,
			.rightBrace, .eof
		])
	}

	@Test("Can parse") func parsin() throws {
		let parsed = try Parser.parse(
			"""
			match thing {
			case .foo(fizz):
				true
			case .bar(buzz), .sup:
				false
			}
			"""
		)[0].cast(MatchStatementSyntax.self)

		#expect(parsed.target.cast(VarExprSyntax.self).name == "thing")
		#expect(parsed.cases.count == 2)

		let case1 = parsed.cases[0].cases[0].cast(EnumMemberExprSyntax.self)
		#expect(case1.receiver == nil)
		#expect(case1.property.lexeme == "foo")
		#expect(case1.params.count == 1)
		#expect(case1.params[0].name == "fizz")
	}
}
