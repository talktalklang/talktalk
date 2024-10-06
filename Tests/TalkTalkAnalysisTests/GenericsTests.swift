//
//  GenericsTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/11/24.
//

@testable import TalkTalkAnalysis
import TalkTalkCore
import Testing
@testable import TypeChecker

struct GenericsTests: AnalysisTest {
	@Test("Gets generic types") func types() throws {
		let decl = try ast("""
		struct Wrapper<Wrapped> {
			let wrapped: Wrapped
		}
		""").cast(AnalyzedStructDecl.self)

		#expect(decl.name == "Wrapper")

		let structType = StructType.extract(from: decl.typeAnalyzed)
		#expect(structType?.name == "Wrapper")

		let type = try #require(decl.environment.type(named: "Wrapper")! as? AnalysisStructType)
		#expect(type.typeParameters.count == 1)
	}

	@Test("Gets bound generic types") func boundGenericTypes() throws {
		let ast = try ast("""
		struct Wrapper<Wrapped> {
			let wrapped: Wrapped
		}

		let wrapper = Wrapper<int>(wrapped: 123)
		wrapper
		""").cast(AnalyzedExprStmt.self).exprAnalyzed

		let variable = try #require(ast as? AnalyzedVarExpr)
		#expect(variable.name == "wrapper")

		let instance = try #require(Instance<StructType>.extract(from: variable.typeAnalyzed))
		#expect(instance.type.name == "Wrapper")
	}

	@Test("Infers generic member types from `self`") func inferSelfMembers() throws {
		let ast = try asts("""
		struct Wrapper<Wrapped> {
			var wrapped: Wrapped

			init(wrapped: Wrapped) {
				self.wrapped = wrapped
			}

			func value() {
				self.wrapped
			}
		}

		let wrapper = Wrapper(wrapped: 123)
		wrapper
		wrapper.value()
		""")

		let exprStmt = ast[3].cast(AnalyzedExprStmt.self)
		let callExpr = exprStmt.exprAnalyzed.cast(AnalyzedCallExpr.self)
		#expect(callExpr.typeAnalyzed == .base(.int))
	}
}
