//
//  BuiltinFunctionTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/30/24.
//

import TalkTalkCore
import Testing
@testable import TypeChecker

struct BuiltinFunctionTests: TypeCheckerTest {
	@Test("Types print") func typesPrint() throws {
		let expr = try Parser.parse("print(123)")
		let context = try solve(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .void)
	}

	@Test("Types _allocate") func types_allocate() throws {
		let expr = try Parser.parse("_allocate(123)")
		let context = try solve(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .base(.pointer))
	}

	@Test("Types _free") func types_free() throws {
		let expr = try Parser.parse("""
		let pointer = _allocate(123)
		_free(pointer)
		""")
		let context = try solve(expr)
		let result = try #require(context[expr[1]])
		#expect(result == .void)
	}

	@Test("Types _deref") func types_deref() throws {
		let expr = try Parser.parse("""
		let pointer = _allocate(123)
		let i: int = _deref(pointer)
		i
		""")
		let context = try solve(expr)
		let result = try #require(context[expr[2]])
		#expect(result == .base(.int))
	}

	@Test("Types _storePtr") func types_storePtr() throws {
		let expr = try Parser.parse("""
		let pointer = _allocate(123)
		_storePtr(pointer, 456)
		""")
		let context = try solve(expr)
		let result = try #require(context[expr[1]])
		#expect(result == .void)
	}

	@Test("Types _hash") func types_hash() throws {
		let expr = try Parser.parse("""
		_hash("sup")
		""")
		let context = try solve(expr)
		#expect(context[expr[0]] == .base(.int))
	}
}
