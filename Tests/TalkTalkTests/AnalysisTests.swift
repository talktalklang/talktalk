//
//  AnalysisTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//

import TalkTalk
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
		#expect(ast("(+ 1 2)").type == .int)
	}

	@Test("Types def") func def() throws {
		let ast = ast("(def foo 1)")
		let def = try #require(ast as? AnalyzedDefExpr)
		#expect(def.type == .int)
	}

	@Test("Types if expr") func ifExpr() {
		#expect(ast("(if false (def a 1) (def a 2))").type == .int)
	}

	@Test("Types func expr") func funcExpr() {
		let fn = ast("""
		(x in (+ x x))
		""")

		#expect(fn.type == .function("_fn_x_12", .int, [.int("x")], []))
	}

	@Test("Types calls") func funcCalls() {
		let res = ast("""
		(def foo (x in (+ x x)))
		(foo 1)
		""")

		#expect(res.type == .int)
	}

	@Test("Types func parameters") func funcParams() throws {
		let ast = ast("""
		(x in (+ x 1))
		""")

		let fn = try #require(ast as? AnalyzedFuncExpr)
		let param = fn.analyzedParams.paramsAnalyzed[0]

		#expect(param.type == .int)
		#expect(fn.type == .function("_fn_x_12", .int, [.int("x")], []))
	}

	@Test("Types captures") func funcCaptures() throws {
		let ast = ast("""
		(x in (y in (+ y x)))
		""")

		let fn = try #require(ast as? AnalyzedFuncExpr)
		let param = fn.analyzedParams.paramsAnalyzed[0]

		#expect(param.name == "x")
		#expect(param.type == .int)
		#expect(fn.type == .function(
			"_fn_x_19",
			.function(
				"_fn_y_18",
				.int,
				[.int("y")],
				[.any("x")]
			),
			[.int("x")],
			[]
		))
		#expect(fn.environment.capturedValues[0].name == "x")

		let nestedFn = fn.bodyAnalyzed[0] as! AnalyzedFuncExpr
		#expect(nestedFn.type == .function("_fn_y_18", .int, [.int("y")], [.any("x")]))

		let capture = nestedFn.environment.captures[0]
		#expect(capture.name == "x")
		#expect(capture.binding.expr.type == .int)
	}

	@Test("Types counter") func counter() throws {
		let main = Analyzer.analyze(Parser.parse("""
		(
			def makeCounter (in
				(def count 0)
				(in
					(def count (+ count 1))
					count
				)
			)
		)

		(def mycounter (call makeCounter))
		(call mycounter)
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
