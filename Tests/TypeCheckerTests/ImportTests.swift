//
//  ImportTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/31/24.
//

import Testing
import TalkTalkSyntax
@testable import TypeChecker

struct ImportTests: TypeCheckerTest {
	@Test("Can import other contexts") func testImport() throws {
		let syntaxA = try Parser.parse("var i = 123")
		let contextA = try infer(syntaxA)

		let syntaxB = try Parser.parse("i")
		let contextB = try infer(syntaxB, imports: [contextA])

		#expect(contextB[syntaxB[0]] == .type(.base(.int)))
	}
}
