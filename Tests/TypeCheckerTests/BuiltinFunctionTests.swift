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
		let context = try infer(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .type(.void))
	}

	@Test("Types _allocate") func types_allocate() throws {
		let expr = try Parser.parse("_allocate(123)")
		let context = try infer(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .type(.base(.pointer)))
	}

	@Test("Types _free") func types_free() throws {
		let expr = try Parser.parse("""
		let pointer = _allocate(123)
		_free(pointer)
		""")
		let context = try infer(expr)
		let result = try #require(context[expr[1]])
		#expect(result == .type(.void))
	}

	@Test("Types _deref") func types_deref() throws {
		let expr = try Parser.parse("""
		let pointer = _allocate(123)
		let i: int = _deref(pointer)
		i
		""")
		let context = try infer(expr)
		let result = try #require(context[expr[2]])
		#expect(result == .type(.base(.int)))
	}

	@Test("Types _storePtr") func types_storePtr() throws {
		let expr = try Parser.parse("""
		let pointer = _allocate(123)
		_storePtr(pointer, 456)
		""")
		let context = try infer(expr)
		let result = try #require(context[expr[1]])
		#expect(result == .type(.void))
	}

	@Test("Types _hash") func types_hash() throws {
		let expr = try Parser.parse("""
		_hash("sup")
		""")
		let context = try infer(expr)
		#expect(context[expr[0]] == .type(.base(.int)))
	}

	@Test("Types _cast") func types_cast() throws {
		let expr = try Parser.parse("""
		let pointer = _allocate(1)
		_storePtr(pointer, "hi")
		let fooCast = _cast(_deref(pointer), int)
		fooCast // this will blow up but the type system is happy
		""")
		let context = try infer(expr)
		let result = try #require(context[expr[2]])
		#expect(result == .type(.base(.int)))
	}
}
