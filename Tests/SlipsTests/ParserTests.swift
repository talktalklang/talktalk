//
//  ParserTests.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import Slips
import Testing

struct ParserTests {
	func parse(_ source: String) -> [Expr] {
		let lexer = Lexer(source)
		var parser = Parser(lexer)
		let result = parser.parse()

		#expect(parser.errors.isEmpty)

		for (token, message) in parser.errors {
			print("Error at \(token): \(message)")
		}

		return result
	}

	@Test("Basic expr") func expr() {
		if let ast = parse("(+ 1 2)")[0] as? CallExpr {
			#expect(type(of: ast) == CallExpr.self)
			#expect(ast.callee.description == "+")
		} else {
			print("nope")
		}
	}

	@Test("def expr") func def() {
		let ast = parse("(def sum (+ x y))")[0] as! DefExpr
		#expect(ast.name.lexeme == "sum")
	}

	@Test("multiple statements") func multiple() {
		let ast = parse("""
		(1)
		(2)
		(def sum (+ x y))
		""")[2] as! DefExpr
		#expect(ast.name.lexeme == "sum")
	}

	@Test("if expr") func ifexpr() {
		let ast = parse("""
		(if true 1 2)
		""")[0] as! IfExpr
		#expect(ast.condition.description == "true")
		#expect(ast.consequence.description == "1")
		#expect(ast.alternative.description == "2")
	}

	@Test("func expr") func funcexpr() throws {
		let ast = parse("""
		(x y in (+ x y))
		""")[0]
		let fn = try #require(ast as? FuncExpr)
		#expect(fn.params.description == "x y")
		#expect(fn.body[0].description == "(+ x y)")
	}

	@Test("call expr") func callExpr() {
		let ast = parse("""
		(x 1)
		""")[0] as! CallExpr
		#expect(ast.callee.description == "x")
		#expect(ast.args[0].description == "1")
	}

	@Test("Explicit call expr") func explicitCallExpr() {
		let ast = parse("""
		(call (x in 1) 2)
		""")[0] as! CallExpr
		#expect(ast.callee.description == "(x in 1)")
		#expect(ast.args[0].description == "2")
	}

	@Test("passing an inline func to a func call") func inlineInlineCall() {
		let ast = parse("""
		(call (x in x) (y in y))
		""")[0] as! CallExpr
		#expect(ast.callee.description == "(x in x)")
		#expect(ast.args[0].description == "(y in y)")
	}

	@Test("Func with no params") func noparams() {
		let ast = parse("""
		(in 2)
		""")[0] as! FuncExpr
		#expect(ast.params.params.isEmpty)
		#expect(ast.body[0].description == "2")
	}

	@Test("Parses counter") func counter() throws {
		let ast = parse("""
		(
			def makeCounter (x in
				(def count 0)
				(x in
					(def count (+ count 1))
					count
				)
			)
		)

		(def counter (call makeCounter))
		(call counter)
		(call counter)
		""")

		#expect(ast.count == 4)
	}

	@Test("deals with newlines") func newlines() throws {
		let ast = parse("""
		(
			def addtwo (x in
				(y in (+ y x))
			)
		)
		(def addfour (addtwo 4))
		(call addfour 2)
		""")

		let def1 = try #require(ast[0] as? DefExpr)
		#expect(def1.name.lexeme == "addtwo")
	}
}
