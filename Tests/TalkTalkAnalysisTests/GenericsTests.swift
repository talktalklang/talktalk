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

struct GenericsTests {
	func ast(_ string: String) -> any AnalyzedSyntax {
		let parsed = try! Parser.parse(.init(path: "genericstest.talk", text: string))
		let context = try! Inferencer(moduleName: "GenericsTests", imports: []).infer(parsed)
		return try! SourceFileAnalyzer.analyze(parsed, in: .init(inferenceContext: context)).last!
	}

	func asts(_ string: String) -> [any AnalyzedSyntax] {
		let parsed = try! Parser.parse(.init(path: "genericstest.talk", text: string))
		let context = try! Inferencer(moduleName: "GenericsTests", imports: []).infer(parsed)
		return try! SourceFileAnalyzer.analyze(parsed, in: .init(inferenceContext: context))
	}

	@Test("Gets generic types") func types() throws {
		let decl = ast("""
		struct Wrapper<Wrapped> {
			let wrapped: Wrapped
		}
		""").cast(AnalyzedStructDecl.self)

		#expect(decl.name == "Wrapper")

		let structType = TypeChecker.StructTypeV1.extractType(from: .resolved(decl.typeAnalyzed))
		#expect(structType?.name == "Wrapper")

		let type = try #require(decl.environment.type(named: "Wrapper")! as? AnalysisStructType)
		#expect(type.typeParameters.count == 1)
	}

	@Test("Gets bound generic types") func boundGenericTypes() throws {
		let ast = ast("""
		struct Wrapper<Wrapped> {
			let wrapped: Wrapped
		}

		let wrapper = Wrapper<int>(wrapped: 123)
		wrapper
		""").cast(AnalyzedExprStmt.self).exprAnalyzed

		let variable = try #require(ast as? AnalyzedVarExpr)
		#expect(variable.name == "wrapper")

		let instance = try #require(InstanceV1<StructTypeV1>.extract(from: variable.typeAnalyzed))
		#expect(instance.type.name == "Wrapper")
	}

	@Test("Infers generic member types from `self`") func inferSelfMembers() throws {
		let ast = asts("""
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
