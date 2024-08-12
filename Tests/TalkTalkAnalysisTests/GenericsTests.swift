//
//  GenericsTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/11/24.
//

import TalkTalkAnalysis
import TalkTalkSyntax
import Testing

struct GenericsTests {
	func ast(_ string: String) -> any AnalyzedSyntax {
		try! SourceFileAnalyzer.analyze(Parser.parse(string), in: .init()).last!
	}

	@Test("Gets generic types") func types() throws {
		let ast = ast("""
		struct Wrapper<Wrapped> {
			let wrapped: Wrapped
		}
		""")

		let s = try #require(ast as? AnalyzedStructExpr)
		#expect(s.name == "Wrapper")

		guard case let .struct(name) = s.typeAnalyzed else {
			#expect(Bool(false), "did not get struct type")
			return
		}

		let type = try #require(s.environment.lookupStruct(named: name))
		#expect(type.typeParameters.count == 1)

		let property = try #require(s.structType.properties["wrapped"])
		#expect(property.type == .generic(.struct("Wrapper"), "Wrapped"))
	}

	@Test("Gets bound generic types") func boundGenericTypes() throws {
		let ast = ast("""
		struct Wrapper<Wrapped> {
			let wrapped: Wrapped
		}

		wrapper = Wrapper<int>(wrapped: 123)
		wrapper
		""")

		let variable = try #require(ast as? AnalyzedVarExpr)
		#expect(variable.name == "wrapper")

		guard case let .instance(instance) = variable.typeAnalyzed else {
			#expect(Bool(false), "did not get struct type")
			return
		}

		#expect(instance.ofType == .struct("Wrapper"))
		#expect((instance.boundGenericTypes["Wrapped"] ?? .none) == ValueType.int)
	}

	@Test("Infers bound generic types") func inferBoundGenericTypes() throws {
		let ast = ast("""
		struct Wrapper<Wrapped> {
			let wrapped: Wrapped
		}

		wrapper = Wrapper(wrapped: 123)
		wrapper
		""")

		let variable = try #require(ast as? AnalyzedVarExpr)
		#expect(variable.name == "wrapper")

		guard case let .instance(instance) = variable.typeAnalyzed else {
			#expect(Bool(false), "did not get struct type")
			return
		}

		#expect(instance.ofType == .struct("Wrapper"))
		#expect((instance.boundGenericTypes["Wrapped"] ?? .none) == ValueType.int)
	}
}
