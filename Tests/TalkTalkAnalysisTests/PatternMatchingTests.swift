//
//  PatternMatchingTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/6/24.
//

import TalkTalkAnalysis
import TalkTalkCore
import TalkTalkSyntax
@testable import TypeChecker
import Testing

struct PatternMatchingTests: AnalysisTest {
	@Test("Can analyze an enum") func enumStmt() async throws {
		let ast = try await ast("""
		enum Thing {
			case foo(String)
			case bar(int)
		}
		""")

		let decl = ast.cast(AnalyzedEnumDecl.self)
		#expect(decl.nameToken.lexeme == "Thing")
		#expect(decl.casesAnalyzed.count == 2)

		#expect(decl.casesAnalyzed[0].nameToken.lexeme == "foo")
		#expect(decl.casesAnalyzed[1].nameToken.lexeme == "bar")

		#expect(decl.casesAnalyzed[0].attachedTypesAnalyzed[0].inferenceType == .base(.string))
		#expect(decl.casesAnalyzed[1].attachedTypesAnalyzed[0].inferenceType == .base(.int))
	}

	@Test("Errors when match is not exhaustive (enums)") func exhaustiveEnum() async throws {
		let ast = try await ast("""
		enum Thing {
			case foo(String)
			case bar(int)
		}

		match Thing.foo("sup") {
		case .foo(let string):
			print(string)
		}
		""")

		let errors = ast.collectErrors()
		#expect(errors.count == 1)
		#expect(errors[0].kind == .matchNotExhaustive("Match not exhaustive. Missing bar"))
	}

	@Test("Doesnt error when not exhaustive with else (enums)") func enumWithElse() async throws {
		let ast = try await ast("""
		enum Thing {
			case foo(String)
			case bar(int)
		}

		match Thing.foo("sup") {
		case .foo(let string):
			print(string)
		else:
			print("it's ok")
		}
		""")

		let errors = ast.collectErrors()
		#expect(errors == [])
	}

	@Test("Can analyze a match statement") func matchStatement() async throws {
		let ast = try await ast("""
		enum Thing {
			case foo(String)
			case bar(int)
		}

		match Thing.bar(123) {
		case .foo(let a):
			a
		case .bar(let a):
			a
		}
		""")

		let stmt = ast.cast(AnalyzedMatchStatement.self)
		let foo = stmt.casesAnalyzed[0].patternAnalyzed!
		#expect(foo.inferenceType == .pattern(
			Pattern(
				type: .enumCase(EnumCase(
					typeName: "Thing",
					name: "foo",
					index: 0,
					attachedTypes: [.base(.string)]
				)),
				arguments: [.variable("a", .base(.string))]
			)
		))

		let bar = stmt.casesAnalyzed[1].patternAnalyzed!
		#expect(bar.inferenceType == .pattern(
			Pattern(
				type: .enumCase(EnumCase(
					typeName: "Thing",
					name: "bar",
					index: 1,
					attachedTypes: [.base(.int)]
				)),
				arguments: [.variable("a", .base(.int))]
			)
		))
	}
}
