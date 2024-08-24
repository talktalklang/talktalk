//
//  AnalysisErrorTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

import TalkTalkAnalysis
import TalkTalkCore
import TalkTalkSyntax
import Testing

struct AnalysisErrorTests: AnalysisTest {
	func errors(
		_ string: String,
		_ kinds: AnalysisErrorKind...,
		at: Testing.SourceLocation = #_sourceLocation
	) async throws {
		try await #expect(ast(string).collectErrors().map(\.kind) == kinds, sourceLocation: at)
	}

	func errors(
		_ string: String,
		_ kindsChecker: ([AnalysisErrorKind]) -> Void
	) async throws {
		try await kindsChecker(ast(string).collectErrors().map(\.kind))
	}

	@Test("Undefined variable") func undefVar() async throws {
		try await errors("foo", .undefinedVariable("foo"))
	}

	@Test("Undefined variable") func foo() async throws {
		try await errors("foo", .undefinedVariable("foo"))
	}

	@Test("Assigning to wrong type local") func assignType() async throws {
		try await errors(
			"""
			var a = "foo"
			a = 123
			""",
			.typeCannotAssign(expected: TypeID(.instance(.struct("String"))), received: TypeID(.int))
		)
	}

	@Test("Assigning to wrong type member") func assignTypeMember() async throws {
		try await errors(
			"""
			struct Person {
				var name: String
			}

			var person = Person(name: "Pat")
			person.name = 123
			""",
			.typeCannotAssign(expected: TypeID(.instance(.struct("String"))), received: TypeID(.int))
		)
	}

	@Test("Assigning to wrong type param") func assignTypeParam() async throws {
		try await errors(
			"""
			func foo(name: int) {}
			foo("sup")
			""",
			.typeCannotAssign(expected: TypeID(.int), received: TypeID(.instance(.struct("String"))))
		)
	}

	@Test("Assigning to immutable var") func reassignLet() async throws {
		try await errors(
			"""
			let foo = "bar"
			foo = "fizz"
			"""
		) { kinds in
			guard kinds.count > 0, case let .cannotReassignLet(variable: variable) = kinds[0] else {
				#expect(Bool(false), "did not get correct kind: \(kinds)")
				return
			}

			#expect(variable.cast(AnalyzedVarExpr.self).name == "foo")
		}
	}

	@Test("Trying to init the same let twice") func reInitLet() async throws {
		try await errors(
			"""
			let foo = "bar"
			let foo = "fizz"
			"""
		) { kinds in
			guard kinds.count > 0, case let .invalidRedeclaration(variable: name, _) = kinds[0] else {
				#expect(Bool(false), "did not get correct kind: \(kinds)")
				return
			}

			#expect(name == "foo")
		}
	}

	@Test("Trying to init the same var twice") func reInitVar() async throws {
		try await errors(
			"""
			var foo = "bar"
			var foo = "fizz"
			"""
		) { kinds in
			guard kinds.count > 0, case let .invalidRedeclaration(variable: name, _) = kinds[0] else {
				#expect(Bool(false), "did not get correct kind: \(kinds)")
				return
			}

			#expect(name == "foo")
		}
	}

	@Test("Assigning to param var") func assignParam() async throws {
		try await errors(
			"""
			func foo(bar) {
				bar = 123
			}
			"""
		) { kinds in
			guard kinds.count > 0, case let .cannotReassignLet(variable: variable) = kinds[0] else {
				#expect(Bool(false), "did not get correct kind: \(kinds)")
				return
			}

			#expect(variable.cast(AnalyzedVarExpr.self).name == "bar")
		}
	}

	@Test("Errors when func doesn't return what it says it will") func badFuncReturn() async throws {
		try await errors(
			"""
			func foo(name: int) -> int {
				"nope"
			}
			""",
			.unexpectedType(expected: .int, received: .instance(.struct("String")), message: "Cannot return String instance, expected int.")
		)
	}

	@Test("Errors with undefined func call inside another func") func nestedBadFunc() async throws {
		try await errors(
			"""
			func foo() {
				nope()
			}
			""",
			.argumentError(expected: -1, received: 0),
			.undefinedVariable("nope")
		)
	}
}
