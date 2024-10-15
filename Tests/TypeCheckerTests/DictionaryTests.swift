//
//  DictionaryTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/28/24.
//

import TalkTalkCore
import Testing
@testable import TypeChecker

@MainActor
struct DictionaryTests: TypeCheckerTest {
	@Test("Types a literal") func literal() throws {
		let syntax = try Parser.parse(
			"""
			["foo": 123]
			"""
		)

		let context = try solve(syntax)
		let dict = context.find(syntax[0])!
		let dictInstance = Instance<StructType>.extract(from: dict)!
		#expect(dictInstance.type.name == "Dictionary")
		#expect(dictInstance.relatedType(named: "Key") == .base(.string))
		#expect(dictInstance.relatedType(named: "Value") == .base(.int))
	}

	@Test("Types a subscript get") func typesSubscriptGet() throws {
		let syntax = try Parser.parse(
			"""
			["foo": 123]["foo"]
			"""
		)

		let context = try solve(syntax)
		let result = context.find(syntax[0])

		#expect(result == .optional(.base(.int)))
	}

	@Test("Types a subscript set") func typesSubscriptSet() throws {
		let syntax = try Parser.parse(
			"""
			var a = ["foo": 123]
			a["foo"] = 123
			"""
		)

		let context = try solve(syntax)
		let result = context.find(syntax[1])
		#expect(result == .base(.int))
	}
}
