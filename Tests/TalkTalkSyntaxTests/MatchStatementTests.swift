//
//  CaseStatementTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/4/24.
//

import Testing
import TalkTalkSyntax

struct MatchStatementTests {
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
			case .foo(let fizz):
				true
			case .bar(buzz):
				false
			}
			"""
		)[0].cast(MatchStatementSyntax.self)

		#expect(parsed.target.cast(VarExprSyntax.self).name == "thing")
		#expect(parsed.cases.count == 2)

		let call1 = parsed.cases[0].pattern.cast(CallExprSyntax.self)
		let case1 = call1.callee.cast(MemberExprSyntax.self)
		#expect(case1.receiver == nil)
		#expect(case1.property == "foo")
		#expect(call1.args.count == 1)
		#expect(call1.args[0].value.cast(LetDeclSyntax.self).name == "fizz")

		let call2 = parsed.cases[1].pattern.cast(CallExprSyntax.self)
		let case2 = call2.callee.cast(MemberExprSyntax.self)
		#expect(case2.receiver == nil)
		#expect(case2.property == "bar")
		#expect(call2.args.count == 1)
		#expect(call2.args[0].value.cast(VarExprSyntax.self).name == "buzz")
	}

	@Test("else clause") func elseClause() throws {
		let parsed = try Parser.parse(
			"""
			match thing {
			case 123:
				true
			else:
				false
			}
			"""
		)[0].cast(MatchStatementSyntax.self)

		#expect(parsed.cases[1].isDefault)
	}
}
