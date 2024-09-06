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
		let foo = stmt.casesAnalyzed[0].optionsAnalyzed[0]
		#expect(foo.inferenceType == .pattern(.enumCase(EnumCase(
			typeName: "Thing",
			name: "foo",
			attachedTypes: [.base(.string)]
		)), [.base(.string)]))

		let bar = stmt.casesAnalyzed[1].optionsAnalyzed[0]
		#expect(bar.inferenceType == .pattern(.enumCase(EnumCase(
			typeName: "Thing",
			name: "bar",
			attachedTypes: [.base(.int)]
		)), [.base(.int)]))
	}
}