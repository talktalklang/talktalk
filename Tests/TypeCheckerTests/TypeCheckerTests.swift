//
//  TypeCheckerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import Foundation
import TalkTalkSyntax
import Testing
@testable import TypeChecker

struct AnyTypeVar {
	static func == (lhs: AnyTypeVar, rhs: TypeVariable) -> Bool {
		lhs.name == rhs.name
	}

	static func == (lhs: TypeVariable, rhs: AnyTypeVar) -> Bool {
		lhs.name == rhs.name
	}

	let name: String

	init(named name: String) {
		self.name = name
	}
}

@MainActor
struct TypeCheckerTests: TypeCheckerTest {
	@Test("Infers int literal") func intLiteral() throws {
		let expr = try Parser.parse("123")
		let context = try infer(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .type(.base(.int)))
	}

	@Test("Infers string literal") func stringLiteral() throws {
		let expr = try Parser.parse(#""hello world""#)
		let context = try infer(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .type(.base(.string)))
	}

	@Test("Infers bool literal") func boolLiteral() throws {
		let expr = try Parser.parse("true")
		let context = try infer(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .type(.base(.bool)))
	}

	@Test("Infers identity function") func identityFunction() throws {
		let expr = try Parser.parse("func(x) { x }")
		let context = try infer(expr)
		let result = try #require(context[expr[0]])

		#expect(
			result == .scheme(
				Scheme(
					name: nil,
					variables: [.typeVar("x", 99)],
					type: .function([.typeVar("x", 99)], .typeVar("x", 99))
				)
			)
		)
	}

	@Test("Infers binary expr with ints") func binaryInts() throws {
		let expr = try Parser.parse("10 + 20")
		let context = try infer(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .type(.base(.int)))
	}

	@Test("Errors binary expr with int and string", .disabled()) func binaryIntAndStringError() throws {
		let expr = try Parser.parse(#"10 + "nope""#)
		let context = try infer(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .type(
			.error(
				.init(
					kind: .constraintError("Infix operator + can't be used with operands int and string"),
					location: expr[0].location
				)
			)
		))
	}

	@Test("Infers binary expr with strings") func binaryStrings() throws {
		let expr = try Parser.parse(#""hello " + "world""#)
		let context = try infer(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .type(.base(.string)))
	}

	@Test("Infers function with binary expr with ints") func binaryIntFunction() throws {
		let expr = try Parser.parse(
			"""
			func(x) { x + 1 }
			"""
		)

		let context = try infer(expr)
		let result = try #require(context[expr[0]])
		#expect(result.asType(in: context) == .function([.base(.int)], .base(.int)))
	}

	@Test("Infers var with base type") func varWithBase() throws {
		let syntax = try Parser.parse("var i = 123")
		let context = try infer(syntax)

		#expect(context.lookupVariable(named: "i") == .base(.int))

		// Ensure substitutions are applied on lookup
		#expect(context[syntax[0]] == .type(.base(.int)))
	}

	@Test("Errors on var reassignment") func varReassignment() throws {
		let syntax = try Parser.parse("var i = 123 ; var i = 456")
		let context = try infer(syntax, expectedErrors: 1)

		#expect(context.errors.count == 1)
	}

	@Test("Infers func calls") func calls() throws {
		let syntax = try Parser.parse(
			"""
			let foo = func(x) { x + x }
			foo(1)
			"""
		)

		let context = try infer(syntax)
		let result = try #require(context[syntax[1]])

		#expect(result == .type(.base(.int)))
	}

	@Test("Infers deferred func calls") func deferredCalls() throws {
		let syntax = try Parser.parse(
			"""
			func foo() { bar() }
			func bar() { 123 } 
			foo()
			"""
		)

		let context = try infer(syntax)
		let result = try #require(context[syntax[2]])

		#expect(result == .type(.base(.int)))
	}

	@Test("Infers let with base type") func letWithBase() throws {
		let syntax = try Parser.parse("let i = 123")
		let context = try infer(syntax)

		#expect(context.lookupVariable(named: "i") == .base(.int))

		// Ensure substitutions are applied on lookup
		#expect(context[syntax[0]] == .type(.base(.int)))
	}

	@Test("Infers named function") func namedFunction() throws {
		let syntax = try Parser.parse(
			"""
			func foo(x) { x + 1 }
			foo
			"""
		)

		let context = try infer(syntax)
		let result = try #require(context[syntax[1]])
		#expect(result.asType(in: context) == .function([.base(.int)], .base(.int)))
	}

	@Test("Infers var with function (it is generic)") func varFuncGeneric() throws {
		let syntax = try Parser.parse("""
		let i = func(x) { x }
		i("sup")
		i(123)
		""")

		let context = try infer(syntax)

		// Ensure identity function getting passed a string returns a string
		#expect(context[syntax[1]] == .type(.base(.string)))

		// Ensure identity function getting passed an int returns an int
		#expect(context[syntax[2]] == .type(.base(.int)))
	}

	@Test("Variables don't leak out of scope") func scopeLeak() throws {
		let syntax = try Parser.parse(
			"""
			func(x) { x }(123)
			x
			"""
		)

		let context = try infer(syntax)
		#expect(context[syntax[0]] == .type(.base(.int)))

		// This test fails
		#expect(context.lookup(syntax: syntax[1]) ==
			.error(
				.init(
					kind: .undefinedVariable("x"),
					location: syntax[1].location
				)

			))
	}

	@Test("Types function return annotations") func funcReturnAnnotations() throws {
		let syntax = try Parser.parse(
			"""
			func(x) -> String { _deref(x) }(123)
			"""
		)

		let context = try infer(syntax)
		#expect(context[syntax[0]] == .type(.base(.string)))
	}

	@Test("Types factorial (recursion test)") func factorial() async throws {
		let syntax = try Parser.parse(
			"""
			func fact(n) {
				if n <= 1 {
					return 1
				} else {
					return n * fact(n - 1)
				}
			}

			fact(3)
			"""
		)

		let context = try infer(syntax)

		// Make sure we've got the function typed properly
		#expect(
			context[syntax[0]] == .scheme(
				Scheme(
					name: "fact",
					variables: [],
					type: .function([.typeVar("n", 99)], .base(.int))
				)
			)
		)

		// Make sure we know what the call return type is
		#expect(context[syntax[1]] == .type(.base(.int)))
	}
}
