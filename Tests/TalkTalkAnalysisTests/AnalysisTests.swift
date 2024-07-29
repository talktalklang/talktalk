//
//  AnalysisTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//

import TalkTalkAnalysis
import TalkTalkSyntax
import Testing

struct AnalysisTests {
	func ast(_ string: String) -> any AnalyzedExpr {
		let analyzed = Analyzer.analyze(Parser.parse(string))

		return (analyzed as! AnalyzedFuncExpr).bodyAnalyzed.last!
	}

	@Test("Types literals") func literals() {
		#expect(ast("true").type == .bool)
		#expect(ast("false").type == .bool)
		#expect(ast("123").type == .int)
	}

	@Test("Types add") func add() {
		#expect(ast("1 + 2").type == .int)
	}

	@Test("Types def") func def() throws {
		let ast = ast("foo = 1")
		let def = try #require(ast as? AnalyzedDefExpr)
		#expect(def.type == .int)
	}

	@Test("Types if expr") func ifExpr() {
		#expect(ast("if true { 1 } else { 2 }").type == .int)
	}

	@Test("Types block expr") func blockExpr() {
		#expect(ast("{ 1 }").type == .int)
	}

	@Test("Types while expr") func whileExpr() {
		#expect(ast("while true { 1 }").type == .int)
	}

	@Test("Types func expr") func funcExpr() {
		let fn = ast("""
		func(x) { x + x }
		""")

		#expect(fn.type == .function("_fn_x_17", .int, [.int("x")], []))
	}

	@Test("Types named func expr") func namedfuncExpr() {
		let fn = ast("""
		func foo(x) { x + x }
		foo
		""")

		#expect(fn.type == .function("foo", .int, [.int("x")], []))
	}

	@Test("Types calls") func funcCalls() {
		let res = ast("""
		foo = func(x) { x + x }
		foo(1)
		""")

		#expect(res.type == .int)
	}

	@Test("Types func parameters") func funcParams() throws {
		let ast = ast("""
		func(x) { 1 + x }
		""")

		let fn = try #require(ast as? AnalyzedFuncExpr)
		let param = fn.analyzedParams.paramsAnalyzed[0]

		#expect(param.type == .int)
		#expect(fn.type == .function("_fn_x_17", .int, [.int("x")], []))
	}

	@Test("Types captures") func funcCaptures() throws {
		let ast = ast("""
		func(x) {
			func(y) {
				y + x
			}
		}
		""")

		let fn = try #require(ast as? AnalyzedFuncExpr)
		let param = fn.analyzedParams.paramsAnalyzed[0]

		#expect(param.name == "x")
		#expect(param.type == .int)
		#expect(fn.type == .function(
			"_fn_x_33",
			.function(
				"_fn_y_32",
				.int,
				[.int("y")],
				[.any("x")]
			),
			[.int("x")],
			[]
		))
		#expect(fn.environment.capturedValues[0].name == "x")

		let nestedFn = fn.bodyAnalyzed[0] as! AnalyzedFuncExpr
		#expect(nestedFn.type == .function("_fn_y_32", .int, [.int("y")], [.any("x")]))

		let capture = nestedFn.environment.captures[0]
		#expect(capture.name == "x")
		#expect(capture.binding.expr.type == .int)
	}

	@Test("Types counter") func counter() throws {
		let main = Analyzer.analyze(Parser.parse("""
		makeCounter = func() {
			count = 0
			func() {
				count = count + 1
				count
			}
		}

		mycounter = makeCounter()
		mycounter()
		"""))

		let def = try #require(main.cast(AnalyzedFuncExpr.self).bodyAnalyzed[0] as? AnalyzedDefExpr)
		let fn = try #require(def.valueAnalyzed.cast(AnalyzedFuncExpr.self))
		#expect(fn.environment.captures.isEmpty)

		let counterFn = try #require(fn.returnsAnalyzed).cast(AnalyzedFuncExpr.self)
		#expect(counterFn.environment.captures.count == 1)
		#expect(counterFn.returnsAnalyzed!.cast(AnalyzedVarExpr.self).type == .int)

		guard case let .function(_, counterReturns, counterParams, counterCaptures) = counterFn.type else {
			#expect(Bool(false), "\(counterFn.type)")
			return
		}

		#expect(counterReturns.description == "int")
		#expect(counterCaptures[0].name == "count")
		#expect(counterParams.params.isEmpty)
	}
}
