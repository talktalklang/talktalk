//
//  StandardLibraryTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/30/24.
//

import Testing
@testable import TypeChecker
import TalkTalkSyntax

struct StandardLibraryTests: TypeCheckerTest {
	@Test("Knows about array") func array() throws {
		let expr = try Parser.parse("[1, 2, 3]")
		let context = try infer(expr)
		let result = try #require(context[expr[0]])

		let instance = try #require(Instance.extract(from: result.asType(in: context)))
		#expect(instance.type.name == "Array")
	}

	@Test("Knows about array subscript") func arraySubscript() throws {
		let expr = try Parser.parse("[1, 2, 3][0]")
		let context = try infer(expr)
		let result = try #require(context[expr[0]])

		#expect(result == .type(.base(.int)))
	}

	@Test("Knows about dictionary") func dict() throws {
		let expr = try Parser.parse("""
		["a": 123, "b": 456]
		""")
		let context = try infer(expr)
		let result = try #require(context[expr[0]])

		let instance = try #require(Instance.extract(from: result.asType(in: context)))
		#expect(instance.type.name == "Dictionary")
	}

	@Test("Knows about dictionary subscript") func dictSubscript() throws {
		let expr = try Parser.parse("""
		["a": 123, "b": 456]["a"]
		""")
		let context = try infer(expr)
		let result = try #require(context[expr[0]])

		#expect(result == .type(.base(.int)))
	}
}
