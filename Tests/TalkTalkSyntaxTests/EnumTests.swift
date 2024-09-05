//
//  EnumTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/4/24.
//

import Testing
import TalkTalkSyntax

struct EnumTests {
	@Test("Can lex an enum") func lexin() throws {
		let tokens = Lexer.collect(
		"""
		enum Thing {
			case foo
		}
		"""
		)

		#expect(tokens.map(\.kind) == [
			.enum,
			.identifier,
			.leftBrace,
			.newline,
			.match,
			.identifier,
			.newline,
			.rightBrace,
			.eof
		])
	}

	@Test("Can parse an enum") func parsin() throws {
		let parsed = try Parser.parse(
			"""
			enum Thing {
				case foo
			}
			"""
		)[0].cast(EnumDeclSyntax.self)

		#expect(parsed.nameToken.lexeme == "Thing")
		#expect(parsed.body.decls[0].cast(EnumCaseDeclSyntax.self).nameToken.lexeme == "foo")
	}

	@Test("Can parse an enum's attached types") func parsinAttachedTypes() throws {
		let parsed = try Parser.parse(
			"""
			enum Thing {
				case foo(String, int)
			}
			"""
		)[0].cast(EnumDeclSyntax.self)

		let decl = parsed.body.decls[0].cast(EnumCaseDeclSyntax.self)
		#expect(decl.nameToken.lexeme == "foo")
		#expect(decl.attachedTypes.count == 2)
		#expect(decl.attachedTypes[0].cast(TypeExprSyntax.self).identifier.lexeme == "String")
		#expect(decl.attachedTypes[1].cast(TypeExprSyntax.self).identifier.lexeme == "int")
	}
}
