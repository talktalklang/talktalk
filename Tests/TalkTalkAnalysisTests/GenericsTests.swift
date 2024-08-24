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
		try! SourceFileAnalyzer.analyze(Parser.parse(.init(path: "", text: string)), in: .init(symbolGenerator: .init(moduleName: "Generics", parent: nil))).last!
	}

	func asts(_ string: String) -> [any AnalyzedSyntax] {
		try! SourceFileAnalyzer.analyze(Parser.parse(.init(path: "", text: string)), in: .init(symbolGenerator: .init(moduleName: "Generics", parent: nil)))
	}

	@Test("Gets generic types") func types() throws {
		let decl = ast("""
		struct Wrapper<Wrapped> {
			let wrapped: Wrapped
		}
		""").cast(AnalyzedStructDecl.self)

		#expect(decl.name == "Wrapper")

		guard case let .struct(name) = decl.typeAnalyzed else {
			#expect(Bool(false), "did not get struct type")
			return
		}

		let type = try #require(decl.environment.lookupStruct(named: name))
		#expect(type.typeParameters.count == 1)

		let property = try #require(decl.structType.properties["wrapped"])

		guard case let .instance(instanceType) = property.typeID.type() else {
			#expect(Bool(false), "did not get instance type")
			return
		}

		#expect(instanceType.ofType == .generic(.struct("Wrapper"), "Wrapped"))
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

		guard case let .instance(instance) = variable.typeAnalyzed else {
			#expect(Bool(false), "did not get struct type")
			return
		}

		#expect(instance.ofType == .struct("Wrapper"))
		#expect((instance.boundGenericTypes["Wrapped"] ?? .none)?.current == ValueType.int)
	}

	@Test("Infers bound generic types") func inferBoundGenericTypes() throws {
		let ast = ast("""
		struct Wrapper<Wrapped> {
			let wrapped: Wrapped
		}

		var wrapper = Wrapper(wrapped: 123)
		wrapper
		""").cast(AnalyzedExprStmt.self).exprAnalyzed

		let variable = try #require(ast as? AnalyzedVarExpr)
		#expect(variable.name == "wrapper")

		guard case let .instance(instance) = variable.typeAnalyzed else {
			#expect(Bool(false), "did not get struct type: \(variable.typeAnalyzed)")
			return
		}

		#expect(instance.ofType == .struct("Wrapper"))
		#expect((instance.boundGenericTypes["Wrapped"] ?? .none)?.current == ValueType.int)
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

		let varExpr = ast[2].cast(AnalyzedExprStmt.self).exprAnalyzed.cast(AnalyzedVarExpr.self)
		guard case let .instance(instance) = varExpr.typeID.current else {
			#expect(Bool(false), "did not get instance") ; return
		}
		#expect(instance.ofType == .struct("Wrapper"))
		#expect(instance.boundGenericTypes["Wrapped"]?.current == .int)

		let exprStmt = ast[3].cast(AnalyzedExprStmt.self)
		let callExpr = exprStmt.exprAnalyzed.cast(AnalyzedCallExpr.self)
		let method = callExpr.calleeAnalyzed
			.cast(AnalyzedMemberExpr.self).memberAnalyzed as! Method

		guard case let .function("value", methodTypeID, [], ["self"]) = method.typeID.current else {
			#expect(Bool(false), "did not get correct method") ; return
		}

		let current = methodTypeID.current
		#expect(current == .int)
	}

	@Test("Infers nested generic types") func inferNested() throws {
		let ast = asts("""
		struct Inner<InnerWrapped> {
			let base: InnerWrapped

			init(base: InnerWrapped) {
				self.base = base
			}
		}

		struct Middle<MiddleWrapped> {
			let inner: Inner<MiddleWrapped>

			init(inner: Inner<MiddleWrapped>) {
				self.inner = inner
			}
		}

		struct Wrapper<Wrapped> {
			let middle: Middle<Inner<Wrapped>>

			init(middle: Middle<Inner<Wrapped>>) {
				self.middle = middle
			}
		}

		let inner = Inner(base: 123)
		let middle = Middle(inner: inner)
		let wrapper = Wrapper(middle: middle)

		wrapper.middle.inner
		""")

		let innerDecl = ast[3].cast(AnalyzedLetDecl.self)
		guard case let .instance(innerInstance) = innerDecl.valueAnalyzed!.typeAnalyzed else {
			#expect(Bool(false), "did not get wrapper instance") ; return
		}
		#expect(innerInstance.boundGenericTypes["InnerWrapped"]?.current == .int)

		let middleDecl = ast[4].cast(AnalyzedLetDecl.self)
		guard case let .instance(middleInstance) = middleDecl.valueAnalyzed!.typeAnalyzed else {
			#expect(Bool(false), "did not get wrapper instance") ; return
		}
		#expect(middleInstance.boundGenericTypes["MiddleWrapped"]?.current == .int)

		let wrapperDecl = ast[5].cast(AnalyzedLetDecl.self)
		guard case let .instance(wrapperInstance) = wrapperDecl.valueAnalyzed!.typeAnalyzed else {
			#expect(Bool(false), "did not get wrapper instance") ; return
		}
		#expect(wrapperInstance.boundGenericTypes["Wrapped"]?.current == .int)

		print("Starting property tests.")

		let middleInnerExpr = ast[6].cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedMemberExpr.self)

		guard case let .instance(innerMember) = middleInnerExpr.memberAnalyzed.typeID.current else {
			#expect(Bool(false), "did not get inner member instance") ; return
		}
		#expect(innerMember.ofType == .struct("Inner"))
		#expect(innerMember.boundGenericTypes["InnerWrapped"]?.current == .int)


		guard case let .instance(middleMember) = middleInnerExpr.receiverAnalyzed.typeID.current else {
			#expect(Bool(false), "did not get middle member instance") ; return
		}
		#expect(middleMember.ofType == .struct("Middle"))
		#expect(middleMember.boundGenericTypes["MiddleWrapped"]?.current == .int)

		let wrapperExpr = middleInnerExpr.receiverAnalyzed
			.cast(AnalyzedMemberExpr.self).receiverAnalyzed
			.cast(AnalyzedVarExpr.self)

		guard case let .instance(wrapperExprInstance) = wrapperExpr.typeAnalyzed else {
			#expect(Bool(false), "did not get wrapper instance") ; return
		}
		#expect(wrapperExprInstance.ofType == .struct("Wrapper"))
		#expect(wrapperExprInstance.boundGenericTypes["Wrapped"]?.current == .int)

//
//		guard case let .instance(middleInstance) = wrapperInstance.boundGenericTypes["Wrapped"]?.current else {
//			#expect(Bool(false), "did not get wrapper instance") ; return
//		}
//
//		guard case let .instance(innerInstance) = middleInstance.boundGenericTypes["MiddleWrapped"]?.current else {
//			#expect(Bool(false), "did not get wrapper instance") ; return
//		}
//
//		#expect(innerInstance.boundGenericTypes["InnerWrapped"]?.current == .int)
//
//
//		let expr = ast.last!.cast(AnalyzedExprStmt.self).exprAnalyzed
//		let inner = try #require(expr as? AnalyzedMemberExpr)
//		#expect(inner.property == "inner")
//		#expect(inner.typeID.current == .instance(
//			InstanceValueType(
//				ofType: .struct("Inner"),
//				boundGenericTypes: ["InnerWrapped": .int]
//			)
//		))
//
//		let middle = try #require(inner.receiverAnalyzed as? AnalyzedMemberExpr)
//		#expect(middle.property == "middle")
//		#expect(middle.typeID.current == .instance(
//			InstanceValueType(
//				ofType: .struct("Middle"),
//				boundGenericTypes: ["MiddleWrapped": .int]
//			)
//		))
//
//		let wrapper = try #require(middle.receiverAnalyzed as? AnalyzedVarExpr)
//		#expect(wrapper.name == "wrapper")
//		#expect(wrapper.typeID.current == .instance(
//			InstanceValueType(
//				ofType: .struct("Wrapper"),
//				boundGenericTypes: ["Wrapped": .int]
//			)
//		))
	}
}
