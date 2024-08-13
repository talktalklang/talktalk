//
//  AnalysisTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//

@testable import TalkTalkAnalysis
import TalkTalkSyntax
import Testing

extension TypeID {
	static var int: TypeID {
		TypeID(.int)
	}

	static func `struct`(_ name: String) -> TypeID {
		TypeID(.struct(name))
	}

	static func instance(_ type: ValueType) -> TypeID {
		TypeID(.instance(
			.init(ofType: type, boundGenericTypes: [:])
		))
	}

	static func function(
		_ name: String,
		_ returning: TypeID,
		_ params: [ValueType.Param],
		_ captures: [String]
	) -> TypeID {
		TypeID(
			.function(name, returning, params, captures)
		)
	}
}

struct AnalysisTests {
	func ast(_ string: String) -> any AnalyzedSyntax {
		try! SourceFileAnalyzer.analyze(
			Parser.parse(string),
			in: .init()
		)
		.last!
	}

	@Test("Types literals") func literals() {
		#expect(ast("true").typeAnalyzed == .bool)
		#expect(ast("false").typeAnalyzed == .bool)
		#expect(ast("123").typeAnalyzed == .int)
	}

	@Test("Types add") func add() {
		#expect(ast("1 + 2").typeAnalyzed == .int)
	}

	@Test("Types def") func def() throws {
		let ast = ast("foo = 1").as(AnalyzedReturnExpr.self)?.valueAnalyzed
		let def = try #require(ast as? AnalyzedDefExpr)
		#expect(def.typeAnalyzed == .int)
		#expect(def.receiverAnalyzed.cast(AnalyzedVarExpr.self).name == "foo")
	}

	@Test("Types if expr") func ifExpr() {
		#expect(ast("a = if true { 1 } else { 2 }").typeAnalyzed == .int)
	}

	@Test("Types if stmt") func ifStmt() {
		#expect(ast("if true { 1 } else { 2 }").typeAnalyzed == .void)
	}

	@Test("Types block expr") func blockExpr() {
		#expect(ast("{ 1 }").typeAnalyzed == .int)
	}

	@Test("Types while expr") func whileExpr() {
		#expect(ast("while true { 1 }").typeAnalyzed == .int)
	}

	@Test("Types func expr") func funcExpr() {
		let fn = ast(
			"""
			func(x) { x + x }
			""")

		#expect(fn.typeAnalyzed == .function("_fn_x_17", .int, [.int("x")], []))
	}

	@Test("Types recursive func expr") func funcExprRecur() {
		let fn = ast(
			"""
			func foo(x) { foo(x) }
			""")

		#expect(
			fn
				.cast(AnalyzedReturnExpr.self).valueAnalyzed?
				.cast(AnalyzedFuncExpr.self).bodyAnalyzed.exprsAnalyzed[0]
				.cast(AnalyzedReturnExpr.self).valueAnalyzed?
				.cast(AnalyzedCallExpr.self).callee.description == "foo"
		)
	}

	@Test("Types named func expr") func namedfuncExpr() {
		let fn = ast(
			"""
			func foo(x) { x + x }
			foo
			"""
		).cast(AnalyzedExprStmt.self).exprAnalyzed

		#expect(fn.typeAnalyzed == .function("foo", .int, [.int("x")], []))
	}

	@Test("Types calls") func funcCalls() {
		let res = ast(
			"""
			foo = func(x) { x + x }
			foo(1)
			""").cast(AnalyzedExprStmt.self).exprAnalyzed

		#expect(res.typeAnalyzed == .int)
	}

	@Test("Types func parameters") func funcParams() throws {
		let ast = ast(
			"""
			func(x) { 1 + x }
			"""
		).cast(AnalyzedReturnExpr.self).valueAnalyzed

		let fn = try #require(ast as? AnalyzedFuncExpr)
		let param = fn.analyzedParams.paramsAnalyzed[0]

		#expect(param.typeAnalyzed == .int)
	}

	@Test("Types functions") func closures() throws {
		let ast = try SourceFileAnalyzer.analyze(
			Parser.parse(
				"""
					i = 1
					func(x) {
						i + 2
					}(2)
				"""), in: .init())

		let result = ast[1]
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedCallExpr.self).calleeAnalyzed
			.cast(AnalyzedFuncExpr.self).typeAnalyzed

		let expected: ValueType = .function("_fn_x_29", .int, [.int("x")], ["i"])
		#expect(result == expected)
	}

	@Test("Emits an error when args don't match params") func arityError() throws {
		let env = Environment()
		let ast = try SourceFileAnalyzer.analyze(Parser.parse("func() {}(123)"), in: env)

		let callExpr = ast[0]
			.cast(AnalyzedReturnExpr.self).valueAnalyzed!
			.cast(AnalyzedCallExpr.self)
		let error = try #require(callExpr.analysisErrors.first)

		#expect(error.kind == .argumentError(expected: 0, received: 1))

		// Make sure the env knows about it too
		let envError = try #require(env.errors.first)
		#expect(envError.kind == .argumentError(expected: 0, received: 1))
	}

	@Test("Types captures") func funcCaptures() throws {
		let ast = ast(
			"""
			func(x) {
				func(y) {
					y + x
				}
			}
		""").as(AnalyzedReturnExpr.self)?.valueAnalyzed

		let fn = try #require(ast as? AnalyzedFuncExpr)
		let param = fn.analyzedParams.paramsAnalyzed[0]

		#expect(param.name == "x")
		#expect(param.typeAnalyzed == .int)
		#expect(
			fn.typeAnalyzed
				== .function(
					"_fn_x_38",
					.function(
						"_fn_y_36",
						.int,
						[.int("y")],
						["x"]
					),
					[.int("x")],
					[]
				))
		#expect(fn.environment.capturedValues.first?.name == "x")

		let nestedFn = fn.bodyAnalyzed.exprsAnalyzed[0].cast(AnalyzedReturnExpr.self).valueAnalyzed as! AnalyzedFuncExpr
		#expect(nestedFn.typeAnalyzed == .function("_fn_y_36", .int, [.int("y")], ["x"]))

		let capture = nestedFn.environment.captures[0]
		#expect(capture.name == "x")
		#expect(capture.binding.type.type() == .int)
	}

	@Test("Types counter") func counter() throws {
		let main = try SourceFileAnalyzer.analyze(
			Parser.parse(
				"""
				makeCounter = func() {
					count = 0
					func() {
						count = count + 1
						count
					}
				}

				mycounter = makeCounter()
				mycounter()
				"""), in: .init())

		let def = try #require(main[0].cast(AnalyzedExprStmt.self).exprAnalyzed as? AnalyzedDefExpr)
		let fn = try #require(def.valueAnalyzed.cast(AnalyzedFuncExpr.self))
		#expect(fn.environment.captures.count == 0)

		let counterFn = try #require(fn.returnsAnalyzed).cast(AnalyzedExprStmt.self).exprAnalyzed.cast(AnalyzedFuncExpr.self)

		#expect(counterFn.environment.captures.count == 1)
		#expect(counterFn.returnsAnalyzed!
			.cast(AnalyzedExprStmt.self).exprAnalyzed
			.cast(AnalyzedVarExpr.self).typeAnalyzed == .int)

		guard case let .function(_, counterReturns, counterParams, counterCaptures) = counterFn.typeAnalyzed
		else {
			#expect(Bool(false), "\(counterFn.typeAnalyzed)")
			return
		}

		#expect(counterReturns.type() == .int)
		#expect(counterCaptures.first == "count")
		#expect(counterParams.isEmpty)
	}

	@Test("Types structs") func structs() throws {
		let ast = ast(
			"""
			struct Person {
				let age: i32

				init(age: i32) {
					self.age = age
				}

				func sup() {
					345
				}
			}
			""")

		let s = try #require(ast as? AnalyzedStructDecl)
		#expect(s.name == "Person")

		guard case let .struct(name) = s.typeAnalyzed else {
			#expect(Bool(false), "did not get struct type")
			return
		}

		let stype = s.environment.lookupStruct(named: "Person")
		let type = try #require(stype)
		#expect(name == "Person")
		#expect(type.methods["init"] != nil)

		#expect(type.properties["age"]!.typeID.type() == .int)
		#expect(type.properties["age"]!.typeID.type() == .int)
		#expect(type.methods["sup"]!.typeID.type() == .function("sup", .int, [], []))
	}

	@Test("Synthesizing init for structs") func synthesizingInitForStructs() throws {
		let ast = ast(
			"""
			struct Person {
				let age: i32

				func sup() {
					345
				}
			}
			""")

		let s = try #require(ast as? AnalyzedStructDecl)
		#expect(s.name == "Person")

		let structType = s.structType
		let initializer = try #require(structType.methods["init"])
		#expect(initializer.params.map(\.key) == ["age"])
	}

	@Test("Types struct Self/self") func selfSelf() throws {
		let ast = ast(
			"""
			struct Person {
				func typeSup() {
					Self
				}

				func sup() {
					self
				}
			}
			""")

		let s = try #require(ast as? AnalyzedStructDecl)
		#expect(s.name == "Person")

		guard case let .struct(name) = s.typeAnalyzed else {
			#expect(Bool(false), "did not get struct type")
			return
		}

		let type = try #require(s.environment.lookupStruct(named: name))
		#expect(name == "Person")
		#expect(type.methods["typeSup"]!.typeID.type() == .function("typeSup", .struct("Person"), [], []))

		guard case let .function(name, returns, _, _) = type.methods["sup"]!.typeID.type() else {
			#expect(Bool(false))
			return
		}

		#expect(name == "sup")
		#expect(returns == .instance(.struct("Person")))
	}

	@Test("Adds error if a decl type can't be found") func declError() throws {
		let ast = ast(
			"""
			struct Person {
				var name: Nope
			}
			""")

		let structDecl = try #require(ast as? AnalyzedStructDecl)
		let varDecl = structDecl.bodyAnalyzed.declsAnalyzed[0].cast(AnalyzedVarDecl.self)

		#expect(varDecl.analysisErrors.count == 1)
	}
}
