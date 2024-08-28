//
//  TypeCheckerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import Testing
@testable import TypeChecker
import TalkTalkSyntax

struct AnyTypeVar {
	static func ==(lhs: AnyTypeVar, rhs: TypeVariable) -> Bool {
		lhs.name == rhs.name
	}

	static func ==(lhs: TypeVariable, rhs: AnyTypeVar) -> Bool {
		lhs.name == rhs.name
	}

	let name: String

	init(named name: String) {
		self.name = name
	}
}

@MainActor
struct TypeCheckerTests {
	func infer(_ expr: [any Syntax]) throws -> InferenceContext {
		let inferencer = InferenceVisitor()
		return inferencer.infer(expr).solve()
	}

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
					variables: [.anyTypeVar(named: "x")],
					type: .function([.anyTypeVar(named: "x")], .anyTypeVar(named: "x"))
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

	@Test("Errors binary expr with int and string") func binaryIntAndStringError() throws {
		let expr = try Parser.parse(#"10 + "nope""#)
		let context = try infer(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .type(.error(.constraintError("Infix operator + can't be used with operands int and string"))))
	}

	@Test("Infers binary expr with strings") func binaryStrings() throws {
		let expr = try Parser.parse(#""hello " + "world""#)
		let context = try infer(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .type(.base(.string)))
	}

	@Test("Infers var with base type") func varWithBase() throws {
		let syntax = try Parser.parse("var i = 123")
		let context = try infer(syntax)
		guard case let .typeVar(result) = try #require(context.lookupVariable(named: "i")) else {
			#expect(Bool(false)) ; return
		}

		// Make sure the variable is actually set
		#expect(context.substitutions[result]! == .base(.int))

		// Ensure substitutions are applied on lookup
		#expect(context[syntax[0]] == .type(.base(.int)))
	}

	@Test("Infers let with base type") func letWithBase() throws {
		let syntax = try Parser.parse("let i = 123")
		let context = try infer(syntax)
		guard case let .typeVar(result) = try #require(context.lookupVariable(named: "i")) else {
			#expect(Bool(false)) ; return
		}

		// Make sure the variable is actually set
		#expect(context.substitutions[result]! == .base(.int))

		// Ensure substitutions are applied on lookup
		#expect(context[syntax[0]] == .type(.base(.int)))
	}

	@Test("Infers var with function (it is generic)") func varFuncGeneric() throws {
		let syntax = try Parser.parse("""
		let i = func(x) { x }
		i("sup")
		i(123)
		""")

		let context = try infer(syntax)
		print()
		// Make sure we've got the function typed properly
		#expect(context[syntax[0]] == .type(.function([.anyTypeVar(named: "x")], .anyTypeVar(named: "x"))))

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
		#expect(context[syntax[1]] == .type(.error(.undefinedVariable("x"))))
	}

	@Test("Types factorial (recursion test)") func factorial() throws {
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
					variables: [.anyTypeVar(named: "n")],
					type: .function([.anyTypeVar(named: "n")], .base(.int))
				)
			)
		)

		// Make sure we know what the call return type is
		#expect(context[syntax[1]] == .type(.base(.int)))
	}
}
