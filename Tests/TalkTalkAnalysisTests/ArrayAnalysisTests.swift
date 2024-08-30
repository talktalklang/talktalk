//
//  ArrayAnalysisTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/20/24.
//

import Testing
import TalkTalkAnalysis

struct ArrayAnalysisTests: AnalysisTest {
	@Test("Works with array literal") func arrayLiteral() async throws {
		let result = try await ast("""
		var a = []
		""")
			.cast(AnalyzedVarDecl.self).valueAnalyzed!

		let instance = InstanceValueType(ofType: .struct("Array"), boundGenericTypes: ["Element": TypeID(.placeholder)])
		#expect(result.typeAnalyzed == .instance(instance))
	}

	@Test("Works with array append") func arrayAppend() async throws {
		let result = try await ast("""
		var d = [:]
		var a = []
		a.append(123)
		a
		""")
			.cast(AnalyzedExprStmt.self).exprAnalyzed.cast(AnalyzedVarExpr.self)

		let instance = InstanceValueType(ofType: .struct("Array"), boundGenericTypes: ["Element": TypeID(.placeholder)])
		#expect(result.typeAnalyzed == .instance(instance))
	}

	@Test("Types array literal") func arrayLiteralTyped() async throws {
		let result = try await ast("""
		var a = [1,2,3]
		""")
			.cast(AnalyzedVarDecl.self).valueAnalyzed!

		guard case let .instance(instance) = result.typeAnalyzed else {
			#expect(Bool(false), "did not get instance"); return
		}

		#expect(instance.ofType == .struct("Array"))
		#expect(instance.boundGenericTypes["Element"]?.current == .int)
	}

	@Test("Types array literal") func arrayLiteralMixedTyped() async throws {
		let result = try await ast("""
		var a = ["fizz"]
		""")
			.cast(AnalyzedVarDecl.self).valueAnalyzed!

		guard case let .instance(instance) = result.typeAnalyzed else {
			#expect(Bool(false), "did not get instance"); return
		}

		#expect(instance.ofType == .struct("Array"))
		#expect(instance.boundGenericTypes["Element"]?.current == .instance(.struct("String", [:])))
	}

	@Test("Types array subscript") func subscriptArray() async throws {
		let result1 = try await ast("""
		[123][0]
		""")
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedSubscriptExpr.self)

		#expect(result1.receiverAnalyzed.typeID.current == ValueType.instance(.struct("Array", ["Element": TypeID(.int)])))
		#expect(result1.typeAnalyzed == .int)

		let result2 = try await ast("""
		["foo"][0]
		""")
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedSubscriptExpr.self)

		#expect(result2.typeAnalyzed == .instance(.struct("String")))
	}

	@Test("Types array elements when it's a generic property") func typesArrayElementWhenProperty() async throws {
		let ast = try await ast("""
		struct WrapperEntry {}

		struct Wrapper {
			var store: Array<WrapperEntry>

			func get(i) {
				self.store[i]
			}
		}
		""")

		let structDecl = try #require(ast as? AnalyzedStructDecl)
		let funcDecl = try #require(structDecl.bodyAnalyzed.declsAnalyzed.last as? AnalyzedFuncExpr)
		let exprStmt = funcDecl.bodyAnalyzed.stmtsAnalyzed[0].cast(AnalyzedExprStmt.self).exprAnalyzed
		let subscriptExpr = exprStmt.cast(AnalyzedSubscriptExpr.self)

		#expect(subscriptExpr.typeID.current == .instance(.struct("WrapperEntry")))
	}
}
