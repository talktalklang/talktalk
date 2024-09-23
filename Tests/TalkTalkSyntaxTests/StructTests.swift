//
//  StructTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/23/24.
//

import TalkTalkSyntax
import Testing

struct StructTests {
	@Test("Can parse a static method") func staticMembers() throws {
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
}
