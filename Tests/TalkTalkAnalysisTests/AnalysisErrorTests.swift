//
//  AnalysisErrorTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

import Testing
import TalkTalkCore
import TalkTalkSyntax
import TalkTalkAnalysis

struct AnalysisErrorTests: AnalysisTest {
	func errors(
		_ at: Testing.SourceLocation = #_sourceLocation,
		_ string: String,
		_ kinds: AnalysisErrorKind...
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
		try await errors(#_sourceLocation, "foo", .undefinedVariable("foo"))
	}

	@Test("Undefined variable") func foo() async throws {
		try await errors(#_sourceLocation, "foo", .undefinedVariable("foo"))
	}

	@Test("Assigning to wrong type local") func assignType() async throws {
		try await errors(
			#_sourceLocation,
			"""
			var a = "foo"
			a = 123
			""",
			.typeCannotAssign(expected: TypeID(.instance(.struct("String"))), received: .int)
		)
	}

	@Test("Assigning to wrong type member") func assignTypeMember() async throws {
		try await errors(
			#_sourceLocation,
			"""
			struct Person {
				var name: String
			}

			var person = Person(name: "Pat")
			person.name = 123
			""",
			.typeCannotAssign(expected: TypeID(.instance(.struct("String"))), received: .int)
		)
	}

	@Test("Assigning to wrong type param") func assignTypeParam() async throws {
		try await errors(
			#_sourceLocation,
			"""
			func foo(name: int) {}
			foo("sup")
			""",
			.typeCannotAssign(expected: .int, received: TypeID(.instance(.struct("String"))))
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
}
