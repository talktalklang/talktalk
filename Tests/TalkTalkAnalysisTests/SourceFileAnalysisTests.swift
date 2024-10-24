//
//  SourceFileAnalysisTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//

@testable import TalkTalkAnalysis
import TalkTalkCore
import Testing
@testable import TypeChecker

struct AnalysisTests {
	func ast(_ string: String) -> any AnalyzedSyntax {
		let parsed = try! Parser.parse(.init(path: "analysistest.talk", text: string))
		let context = try! Typer(module: "AnalysisTests", imports: []).solve(parsed)
		return try! SourceFileAnalyzer.analyze(parsed, in: .init(inferenceContext: context)).last!
	}

	func asts(_ string: String) -> [any AnalyzedSyntax] {
		let parsed = try! Parser.parse(.init(path: "analysistest.talk", text: string))
		let context = try! Typer(module: "AnalysisTests", imports: []).solve(parsed)
		return try! SourceFileAnalyzer.analyze(parsed, in: .init(inferenceContext: context))
	}

	@Test("Types literals") func literals() {
		#expect(ast("true").typeAnalyzed == .base(.bool))
		#expect(ast("false").typeAnalyzed == .base(.bool))
		#expect(ast("123").typeAnalyzed == .base(.int))
	}

	@Test("Types string literals") func strings() {
		#expect(ast(#""hello world""#).typeAnalyzed == .base(.string))
	}

	@Test("Types add") func add() {
		#expect(ast("1 + 2").typeAnalyzed == .base(.int))
	}

	@Test("Types def") func def() throws {
		let ast = try #require(ast("var foo = 1").as(AnalyzedVarDecl.self))
		let def = try #require(ast.valueAnalyzed as? AnalyzedLiteralExpr)
		#expect(def.typeAnalyzed == .base(.int))
		#expect(ast.name == "foo")
	}

	@Test("Types let") func typesLet() throws {
		let ast = ast("let foo = 1").cast(AnalyzedLetDecl.self)
		#expect(ast.name == "foo")
	}

	@Test("Types if expr") func ifExpr() {
		let expr = ast("return if true { 1 } else { 2 }").cast(AnalyzedReturnStmt.self).valueAnalyzed!
		#expect(expr is AnalyzedIfExpr)
		#expect(expr.typeAnalyzed == .base(.int))

		let expr2 = ast("return if true { \"hi\" } else { \"yo\" }").cast(AnalyzedReturnStmt.self).valueAnalyzed!
		#expect(expr2 is AnalyzedIfExpr)
		#expect(expr2.typeAnalyzed == .base(.string))
	}

	@Test("Types if stmt") func ifStmt() {
		#expect(ast("if true { 1 } else { 2 }").typeAnalyzed == .void)
	}

	@Test("Types block expr") func blockExpr() {
		#expect(ast("{ 1 }").typeAnalyzed == .base(.int))
	}

	@Test("Types while expr") func whileExpr() {
		#expect(ast("while true { 1 }").typeAnalyzed == .base(.int))
	}

	@Test("Types func expr") func funcExpr() {
		let fn = ast(
			"""
			func(x) { x + 1 }
			""")

		#expect(
			fn.typeAnalyzed == .function([.resolved(.base(.int))], .resolved(.base(.int)))
		)
	}

	@Test("Sets implicitlyReturns for single expr statement func bodies") func implicitReturn() {
		let fn = ast(
			"""
			func() { 123 }
			""")

		let stmt = fn
			.cast(AnalyzedFuncExpr.self).bodyAnalyzed.stmtsAnalyzed[0]
			.cast(AnalyzedExprStmt.self)

		#expect(stmt.exitBehavior == .return)
	}

	@Test("Types recursive func expr") func funcExprRecur() {
		let fn = ast(
			"""
			func foo(x) { foo(x) }
			""")

		let passed = fn
			.cast(AnalyzedFuncExpr.self).bodyAnalyzed.stmtsAnalyzed[0]
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedCallExpr.self).callee.description == "foo"

		#expect(passed)
	}

	@Test("Types named func expr") func namedfuncExpr() {
		let fn = ast(
			"""
			func foo(x) { x + 1 }
			foo
			"""
		).cast(AnalyzedExprStmt.self).exprAnalyzed

		#expect(fn.typeAnalyzed == .function([.resolved(.base(.int))], .resolved(.base(.int))))
	}

	@Test("Types simple calls") func funcSimpleCalls() {
		let res = ast(
			"""
			func(x) { x }(1)
			""").cast(AnalyzedCallExpr.self)

		#expect(res.typeAnalyzed == .base(.int))
	}

	@Test("Types calls") func funcCalls() {
		let res = ast(
			"""
			let foo = func(x) { x + x }
			foo(1)
			""").cast(AnalyzedExprStmt.self).exprAnalyzed

		#expect(res.typeAnalyzed == .base(.int))
	}

	@Test("Types func parameters") func funcParams() throws {
		let ast = ast(
			"""
			func(x) { 1 + x }
			"""
		)

		let fn = try #require(ast as? AnalyzedFuncExpr)
		let param = fn.analyzedParams.paramsAnalyzed[0]

		#expect(param.typeAnalyzed == .base(.int))
	}

	@Test("Types pointer arithmetic") func pointers() throws {
		let ast = ast(
			"""
			func foo(p: pointer) {
				p + 1
			}
			"""
		)

		#expect(ast.cast(AnalyzedFuncExpr.self).returnType == .base(.pointer))
	}

	@Test("Types functions") func closures() throws {
		let asts = asts(
			"""
				let i = 1
				func(x) {
					i + 2
				}(2)
			"""
		)

		let result = asts[1].cast(AnalyzedCallExpr.self)

		#expect(result.typeAnalyzed == .base(.int))
	}

	@Test("Emits an error when args don't match params") func arityError() throws {
		let ast = asts("func() {}(123)")

		let callExpr = ast[0]
			.cast(AnalyzedCallExpr.self)
		let error = try #require(callExpr.analysisErrors.first)

		#expect(error.kind == .inferenceError(.argumentError(expected: 0, actual: 1)))
	}

	@Test("Types captures") func funcCaptures() throws {
		let ast = ast(
			"""
				func(x: int) {
					func(y) {
						y + x
					}
				}
			""")

		let fn = try #require(ast as? AnalyzedFuncExpr)
		let param = fn.analyzedParams.paramsAnalyzed[0]

		#expect(param.name == "x")
		#expect(param.typeAnalyzed == .base(.int))
		#expect(
			fn.typeAnalyzed == .function(
				[.resolved(.base(.int))],
				.resolved(
					.function(
						[.resolved(.base(.int))],
						.resolved(.base(.int))
					)
				)
			)
		)
		#expect(fn.environment.capturedValues.first?.name == "x")

		let nestedFn = fn.bodyAnalyzed.stmtsAnalyzed[0]
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedFuncExpr.self)
		#expect(nestedFn.typeAnalyzed == .function([.resolved(.base(.int))], .resolved(.base(.int))))

		#expect(nestedFn.environment.captures.count == 1)
		let capture = try #require(nestedFn.environment.captures.first)
		#expect(capture.name == "x")
		#expect(capture.binding.type == .base(.int))
	}

	@Test("Types counter") func counter() throws {
		let main = asts(
			"""
			let makeCounter = func() {
				let count = 0
				return func() {
					count = count + 1
					return count
				}
			}

			let mycounter = makeCounter()
			mycounter()
			"""
		)

		let def = try #require(main[0].cast(AnalyzedLetDecl.self))
		let makeCounter = try #require(def.valueAnalyzed!.cast(AnalyzedFuncExpr.self))
		#expect(makeCounter.environment.captures.count == 0)
		#expect(makeCounter.typeAnalyzed == .function([], .resolved(.function([], .resolved(.base(.int))))))
		#expect(makeCounter.returnType == .function([], .resolved(.base(.int))))

		let increment = try #require(makeCounter.bodyAnalyzed.stmtsAnalyzed.last)
			.cast(AnalyzedReturnStmt.self).valueAnalyzed!
			.cast(AnalyzedFuncExpr.self)

		#expect(increment.typeAnalyzed == .function([], .resolved(.base(.int))))
		#expect(increment.environment.captures.count == 1)
		#expect(increment.environment.captures[0].name == "count")
	}

	@Test("Errors on bad struct instantiating") func badStruct() {
		let ast = ast("""
		var a = Nope()
		""")
		.cast(AnalyzedVarDecl.self).valueAnalyzed!

		let callExpr = ast
			.cast(AnalyzedCallExpr.self).calleeAnalyzed
			.cast(AnalyzedVarExpr.self)
		#expect(!callExpr.analysisErrors.isEmpty)
		#expect(callExpr.analysisErrors[0].kind == .undefinedVariable("Nope"))
	}

	@Test("Types structs") func structs() throws {
		let ast = ast(
			"""
			struct Person {
				let age: int

				init(age: int) {
					self.age = age
				}

				func sup() {
					345
				}
			}
			""")

		let s = try #require(ast as? AnalyzedStructDecl)
		#expect(s.name == "Person")

		let structType = TypeChecker.StructType.extract(from: s.typeAnalyzed)
		#expect(structType?.name == "Person")

		let stype = try s.environment.type(named: "Person")
		let type = try #require(stype)
		#expect(type.name == "Person")
		#expect(type.methods["init"] != nil)

		#expect(type.properties["age"]!.inferenceType == .base(.int))
		#expect(type.methods["sup"]!.inferenceType == .function([], .resolved(.base(.int))))
	}

	@Test("Types calling struct methods on self") func selfMethodCalls() throws {
		let ast = ast(
			"""
			struct Person<Thing> {
				let age: int

				init(age: int) {
					self.age = age
				}

				func get(index) {
					self.at(index)
				}

				func at(index) -> Thing {
					123
				}
			}
			""")

		let s = try #require(ast as? AnalyzedStructDecl)
		#expect(s.name == "Person")

		let structType = try #require(TypeChecker.StructType.extract(from: s.typeAnalyzed))

		#expect(structType.name == "Person")

		let stype = try s.environment.type(named: "Person")
		let type = try #require(stype)
		#expect(type.name == "Person")
		#expect(type.methods["init"] != nil)

		#expect(type.methods["get"]!.returnTypeID == .base(.int))
	}

	@Test("Synthesizing init for structs") func synthesizingInitForStructs() throws {
		let ast = ast(
			"""
			struct Person {
				let age: int

				func sup() {
					345
				}
			}
			""")

		let s = try #require(ast as? AnalyzedStructDecl)
		#expect(s.name == "Person")

		let structType = s.structType
		let initializer = try #require(structType.methods["init"])
		#expect(initializer.params == [.base(.int)])
	}

	@Test("Types struct Self/self") func selfSelf() throws {
		let ast = ast(
			"""
			struct Person {
				func sup() {
					self
				}
			}
			""")

		let s = try #require(ast as? AnalyzedStructDecl)
		let type = try #require(try! s.environment.type(named: "Person"))

		let stype = StructType.extract(from: s.typeAnalyzed)!
		#expect(type.methods["sup"]!.returnTypeID == .self(stype))
	}

	@Test("Adds error if a decl type can't be found") func declError() throws {
		let ast = ast(
			"""
			struct Person {
				var name: Nope
			}
			""")

		let structDecl = try #require(ast as? AnalyzedStructDecl)
		let varDecl = structDecl.bodyAnalyzed.declsAnalyzed[0].cast(AnalyzedPropertyDecl.self)

		#expect(varDecl.analysisErrors.count == 1)
	}

	@Test("Can analyze interpolated strings") func interpolatedStrings() throws {
		let ast = ast(
			#"""
			"foo \(true) bar"
			"""#
		)

		let interpolated = ast
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedInterpolatedStringExpr.self)

		#expect(interpolated.segmentsAnalyzed.count == 3)
		#expect(interpolated.segmentsAnalyzed[0].asString! == "foo ")
		#expect(interpolated.segmentsAnalyzed[1].asExpr!.exprAnalyzed.cast(AnalyzedLiteralExpr.self).value == .bool(true))
		#expect(interpolated.segmentsAnalyzed[2].asString! == " bar")
	}

	@Test("Can analyze logical and") func logicalAnd() throws {
		let ast = ast(
			#"""
			true && false
			"""#
		)

		let interpolated = ast
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedLogicalExpr.self)

		#expect(interpolated.lhsAnalyzed.cast(AnalyzedLiteralExpr.self).value == .bool(true))
		#expect(interpolated.rhsAnalyzed.cast(AnalyzedLiteralExpr.self).value == .bool(false))
	}
}
