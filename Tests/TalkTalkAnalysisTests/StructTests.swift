//
//  StructTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/23/24.
//

@testable import TalkTalkAnalysis
import TalkTalkSyntax
import Testing
@testable import TypeChecker

struct StructTests: AnalysisTest {
	@Test("Static method") func staticMethod() async throws {
		let ast = try await asts("""
		struct Basic {
			static func hello() {
				123
			}
		}
		""")[0]
			.cast(AnalyzedStructDecl.self)

		#expect(ast.structType.methods["hello"]!.isStatic)
	}

	@Test("Static var") func staticVar() async throws {
		let ast = try await asts("""
		struct Basic {
			static var hello: int
		}
		""")[0]
			.cast(AnalyzedStructDecl.self)

		#expect(ast.structType.properties["hello"]!.isStatic)
	}

	@Test("Static let") func staticLet() async throws {
		let ast = try await asts("""
		struct Basic {
			static let hello: int
		}
		""")[0]
			.cast(AnalyzedStructDecl.self)

		#expect(ast.structType.properties["hello"]!.isStatic)
	}
}
