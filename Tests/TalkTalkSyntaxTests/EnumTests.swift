//
//  EnumTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/4/24.
//

import TalkTalkCore
import Testing

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
			.enum, .identifier, .leftBrace, .newline,
			.case, .identifier, .newline,
			.rightBrace, .eof,
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

	@Test("Can parse a qualified enum case") func parsinQualifiedEnumCase() throws {
		let parsed = try Parser.parse(
			"""
			Thing.foo(123)
			"""
		)[0].cast(ExprStmtSyntax.self).expr.cast(CallExprSyntax.self)

		let callee = parsed.callee.cast(MemberExprSyntax.self)
		#expect(callee.receiver?.cast(VarExprSyntax.self).name == "Thing")
		#expect(callee.property == "foo")
		#expect(parsed.args.count == 1)
		#expect(parsed.args[0].value.cast(LiteralExprSyntax.self).value == .int(123))
	}

	@Test("Can parse unqualified member case") func parsinUnqualifiedMemberCase() throws {
		let parsed = try Parser.parse(
			"""
			.foo(123)
			"""
		)[0].cast(ExprStmtSyntax.self).expr.cast(CallExprSyntax.self)

		// We treat unqualified member cases (with no receiver) as calls.
		let callee = parsed.callee.cast(MemberExprSyntax.self)
		#expect(callee.receiver == nil)
		#expect(callee.property == "foo")
		#expect(parsed.args.count == 1)
		#expect(parsed.args[0].value.cast(LiteralExprSyntax.self).value == .int(123))
	}
}
