//
//  BlockTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/22/24.
//

import TalkTalkSyntax
import Testing

struct BlockTests {
	@Test("Basic") func empty() throws {
		let parsed = try Parser.parse(
			"""
			{}
			"""
		)[0].cast(BlockStmtSyntax.self)

		#expect(parsed.stmts.isEmpty)
	}

	@Test("Basic params") func params() throws {
		let parsed = try Parser.parse(
			"""
			{ a in a }
			"""
		)[0].cast(BlockStmtSyntax.self)

		#expect(parsed.stmts.isEmpty)
		#expect(parsed.params?.count == 1)
	}
}
