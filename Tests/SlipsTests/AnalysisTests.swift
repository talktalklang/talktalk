//
//  AnalysisTests.swift
//  Slips
//
//  Created by Pat Nakajima on 7/26/24.
//

import Slips
import Testing

struct AnalysisTests {
	func ast(_ string: String) -> any AnalyzedExpr {
		let analyzer = Analyzer()
		let environment = Analyzer.Environment()

		return Parser.parse(string).map { $0.accept(analyzer, environment) }.last!
	}

	@Test("Types literals") func literals() {
		#expect(ast("true").type == .bool)
		#expect(ast("false").type == .bool)
		#expect(ast("123").type == .int)
	}

	@Test("Types add") func add() {
		#expect(ast("(+ 1 2)").type == .int)
	}

	@Test("Types def") func def() {
		#expect(ast("(def foo 1)").type == .int)
		#expect(ast("(def foo 1) foo").type == .int)
	}

	@Test("Types if expr") func ifExpr() {
		#expect(ast("(if false (def a 1) (def a 2))").type == .int)
	}

	@Test("Types func expr") func funcExpr() {
		let fn = ast("""
		(x in (+ x x))
		""")

		#expect(fn.type == .function(.int, [.int("x")]))
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
		#expect(fn.type == .function(.int, [.int("x")]))
	}
}
