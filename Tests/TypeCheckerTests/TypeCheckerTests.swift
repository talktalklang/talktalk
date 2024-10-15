//
//  TypeCheckerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import Foundation
import TalkTalkCore
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
		let context = try solve(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .base(.int))
	}

	@Test("Infers string literal") func stringLiteral() throws {
		let expr = try Parser.parse(#""hello world""#)
		let context = try solve(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .base(.string))
	}

	@Test("Infers bool literal") func boolLiteral() throws {
		let expr = try Parser.parse("true")
		let context = try solve(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .base(.bool))
	}

	@Test("Infers identity function") func identityFunction() throws {
		let expr = try Parser.parse("func(x) { x }")
		let context = try solve(expr)

		let result = try #require(context[expr[0]])

		guard case let .function(params, returns) = result else {
			#expect(Bool(false), "scheme type is not a function")
			return
		}

		#expect(params == [.resolved(.typeVar("x", 1))])
		#expect(returns == .resolved(.typeVar("x", 1)))
	}

	@Test("Infers binary expr with ints") func binaryInts() throws {
		let expr = try Parser.parse("10 + 20")
		let context = try solve(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .base(.int))
	}

	@Test("Errors binary expr with int and string", .disabled("for now")) func binaryIntAndStringError() throws {
		let expr = try Parser.parse(#"10 + "nope""#)
		let context = try solve(expr, expectedDiagnostics: 1)
		let result = try #require(context[expr[0]])

		#expect(context.diagnostics.count == 1)

		#expect(context.diagnostics[0].severity == .error)
		#expect(context.diagnostics[0].message == "Infix operator + can't be used with operands int and string")
		#expect(context.diagnostics[0].location == expr[0].location)

		#expect(result == .any)
	}

	@Test("Infers binary expr with strings") func binaryStrings() throws {
		let expr = try Parser.parse(#""hello " + "world""#)
		let context = try solve(expr)
		let result = try #require(context[expr[0]])
		#expect(result == .base(.string))
	}

	@Test("Infers function with binary expr with ints") func binaryIntFunction() throws {
		let expr = try Parser.parse(
			"""
			func(x) { x + 1 }
			"""
		)

		let context = try solve(expr)
		let result = try #require(context[expr[0]])

		#expect(result == .function([.resolved(.base(.int))], .resolved(.base(.int))))
	}

	@Test("Infers var with base type") func varWithBase() throws {
		let syntax = try Parser.parse("var i = 123 ; i")
		let context = try solve(syntax)

		#expect(context.type(named: "i") == .resolved(.base(.int)))

		// Ensure substitutions are applied on lookup
		#expect(context[syntax[1]] == .base(.int))
	}

	@Test("Errors on var reassignment") func varReassignment() throws {
		let syntax = try Parser.parse("var i = 123 ; var i = 456")
		let context = try solve(syntax, expectedDiagnostics: 1)

		#expect(context.diagnostics.count == 1)
	}

	@Test("Infers func calls") func calls() throws {
		let syntax = try Parser.parse(
			"""
			let foo = func(x) { x + x }
			foo(1)
			"""
		)

		let context = try solve(syntax)
		let result = try #require(context[syntax[1]])

		#expect(result == .base(.int))
	}

	@Test("Infers deferred func calls") func deferredCalls() throws {
		let syntax = try Parser.parse(
			"""
			func foo() { bar() }
			func bar() { 123 } 
			foo()
			"""
		)

		let context = try solve(syntax)
		let result = try #require(context[syntax[2]])

		#expect(result == .base(.int))
	}

	@Test("Infers let with base type") func letWithBase() throws {
		let syntax = try Parser.parse("let i = 123 ; i")
		let context = try solve(syntax)

		#expect(context.type(named: "i") == .resolved(.base(.int)))

		// Ensure substitutions are applied on lookup
		#expect(context[syntax[1]] == .base(.int))
	}

	@Test("Infers named function") func namedFunction() throws {
		let syntax = try Parser.parse(
			"""
			func foo(x) { x + 1 }
			foo
			"""
		)

		let context = try solve(syntax)
		let result = try #require(context[syntax[1]])
		#expect(result == .function(
			[.resolved(.base(.int))],
			.resolved(.base(.int))
		))
	}

	@Test("Infers var with function (it is generic)") func varFuncGeneric() throws {
		let syntax = try Parser.parse("""
		let i = func(x) { x }
		i("sup")
		i(123)
		""")

		let context = try solve(syntax)

		// Ensure identity function getting passed a string returns a string
		#expect(context[syntax[1]] == .base(.string))

		// Ensure identity function getting passed an int returns an int
		#expect(context[syntax[2]] == .base(.int))
	}

	@Test("Variables don't leak out of scope") func scopeLeak() throws {
		let syntax = try Parser.parse(
			"""
			func(x) { x }(123)
			x
			"""
		)

		let context = try solve(syntax, expectedDiagnostics: 1)
		#expect(context[syntax[0]] == .base(.int))
		#expect(context.diagnostics[0].message == "Undefined variable: `x`")
	}

	@Test("Types function return annotations") func funcReturnAnnotations() throws {
		let syntax = try Parser.parse(
			"""
			func(x) -> String { _deref(x) }(123)
			"""
		)

		// Allowing a diagnostic here because we're passing an int where a pointer is wanted and that's
		// not really the point of this test
		let context = try solve(syntax, expectedDiagnostics: 1)
		#expect(context[syntax[0]] == .base(.string))
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

		let context = try solve(syntax)

		// Make sure we've got the function typed properly
		#expect(
			context[syntax[0]] == .function([.resolved(.base(.int))], .resolved(.base(.int)))
		)

		// Make sure we know what the call return type is
		#expect(context[syntax[1]] == .base(.int))
	}

	@Test("Types logical AND") func logicalAnd() async throws {
		let syntax = try Parser.parse("true && false")
		let context = try solve(syntax)
		#expect(context[syntax[0]] == .base(.bool))
	}

	@Test("Errors when logical AND operand isn't bool") func logicalAndError() async throws {
		let context1 = try solve(Parser.parse("123 && false"), expectedDiagnostics: 1)
		#expect(context1.diagnostics.count == 1)

		let context2 = try solve(Parser.parse("false && 123"), expectedDiagnostics: 1)
		#expect(context2.diagnostics.count == 1)
	}

	@Test("Types logical OR") func logicalOr() async throws {
		let syntax = try Parser.parse("true || false")
		let context = try solve(syntax)
		#expect(context[syntax[0]] == .base(.bool))
	}

	@Test("Errors when logical OR operand isn't bool") func logicalOrError() async throws {
		let context1 = try solve(Parser.parse("123 || false"), expectedDiagnostics: 1)
		#expect(context1.diagnostics.count == 1)

		let context2 = try solve(Parser.parse("false || 123"), expectedDiagnostics: 1)
		#expect(context2.diagnostics.count == 1)
	}
}
