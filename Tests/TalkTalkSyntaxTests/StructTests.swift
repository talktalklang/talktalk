//
//  StructTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/23/24.
//

import TalkTalkSyntax
import Testing

struct StructTests {
	@Test("Can parse a static method") func staticMethod() throws {
		let parsed = try Parser.parse(
			"""
			struct Basic {
				static func hello() {}
			}
			"""
		)

		let structDef = try #require(parsed[0] as? StructDecl)
		let method = structDef.body.decls[0].cast(FuncExprSyntax.self)
		#expect(method.name?.lexeme == "hello")
		#expect(method.isStatic)
	}

	@Test("Can parse a static var") func staticVar() throws {
		let parsed = try Parser.parse(
			"""
			struct Basic {
				static var hello: String
			}
			"""
		)

		let structDef = try #require(parsed[0] as? StructDecl)
		let method = structDef.body.decls[0].cast(VarDeclSyntax.self)
		#expect(method.name == "hello")
		#expect(method.isStatic)
	}

	@Test("Can parse a static let") func staticLet() throws {
		let parsed = try Parser.parse(
			"""
			struct Basic {
				static let hello: String
			}
			"""
		)

		let structDef = try #require(parsed[0] as? StructDecl)
		let method = structDef.body.decls[0].cast(LetDeclSyntax.self)
		#expect(method.name == "hello")
		#expect(method.isStatic)
	}
}
