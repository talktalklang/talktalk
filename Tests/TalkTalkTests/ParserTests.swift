//
//  ParserTests.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalk
import Testing

struct TalkTalkParserTests {
	func parse(_ source: String) -> [Expr] {
		let lexer = TalkTalkLexer(source)
		var parser = Parser(lexer)
		let result = parser.parse()

		#expect(parser.errors.isEmpty)

		for (token, message) in parser.errors {
			print("Error at \(token): \(message)")
		}

		return result
	}

	@Test("Literals") func literals() throws {
		#expect(parse("1")[0].cast(LiteralExprSyntax.self).value == .int(1))
		#expect(parse("true")[0].cast(LiteralExprSyntax.self).value == .bool(true))
		#expect(parse("false")[0].cast(LiteralExprSyntax.self).value == .bool(false))
	}

	@Test("Basic expr") func binaryexpr() throws {
		let ast = parse("1 + 2")[0]
		let expr = try #require(ast as? BinaryExpr)
		#expect(expr.lhs.description == "1")
		#expect(expr.rhs.description == "2")
		#expect(expr.op == .plus)
	}

	@Test("def expr") func def() {
		let ast = parse("foo = 123")[0] as! DefExpr
		#expect(ast.name.lexeme == "foo")
		#expect(ast.value.cast(LiteralExprSyntax.self).value == .int(123))
	}

	@Test("Grouped expr") func grouped() {
		let ast = parse("(123)")[0] as! LiteralExprSyntax
		#expect(ast.value == .int(123))
	}

	@Test("multiple statements") func multiple() {
		let ast = parse("""
		(1)
		(2)
		sum = 1 + 2
		""")[2] as! DefExpr
		#expect(ast.name.lexeme == "sum")
		#expect(ast.value.cast(BinaryExprSyntax.self).op == .plus)
	}

	@Test("if expr") func ifexpr() {
		let ast = parse("""
		if true {
			1
		} else {
			2
		}
		""")[0] as! IfExpr
		#expect(ast.condition.description == "true")
		#expect(ast.consequence.description == "1")
		#expect(ast.alternative.description == "2")
	}

	@Test("while expr") func whileexpr() {
		let ast = parse("""
		while true {
			123
			456
		}
		""")[0] as! WhileExpr
		#expect(ast.condition.description == "true")
		#expect(ast.body.exprs[0].cast(LiteralExprSyntax.self).value == .int(123))
	}

	@Test("func expr") func funcexpr() throws {
		let ast = parse("""
		func(x, y) { x + y } 
		""")[0]
		let fn = try #require(ast as? FuncExpr)
		#expect(fn.params.params[0].name == "x")
		#expect(fn.params.params[1].name == "y")
		#expect(fn.body[0].cast(BinaryExprSyntax.self).lhs.description == "x")
		#expect(fn.body[0].cast(BinaryExprSyntax.self).rhs.description == "y")
		#expect(fn.body[0].cast(BinaryExprSyntax.self).op == .plus)
	}

	@Test("named func expr") func namedfuncexpr() throws {
		let ast = parse("""
		func foo(x, y) { x + y } 
		""")[0]
		let fn = try #require(ast as? FuncExpr)
		#expect(fn.name == "foo")
		#expect(fn.params.params[0].name == "x")
		#expect(fn.params.params[1].name == "y")
		#expect(fn.body[0].cast(BinaryExprSyntax.self).lhs.description == "x")
		#expect(fn.body[0].cast(BinaryExprSyntax.self).rhs.description == "y")
		#expect(fn.body[0].cast(BinaryExprSyntax.self).op == .plus)
	}

	@Test("call expr") func callExpr() {
		let ast = parse("""
		foo(1)
		""")[0] as! CallExpr
		#expect(ast.callee.description == "foo")
		#expect(ast.args[0].description == "1")
	}

	@Test("passing an inline func to a func call") func inlineInlineCall() {
		let ast = parse("""
		func(x) { x }(func(y) { y })
		""")[0] as! CallExpr
		#expect(ast.callee.cast(FuncExprSyntax.self).params.params[0].name == "x")
		#expect(ast.args[0].cast(FuncExprSyntax.self).params.params[0].name == "y")
	}

	@Test("Func with no params") func noparams() {
		let ast = parse("""
		func() { 2 }
		""")[0] as! FuncExpr
		#expect(ast.params.params.isEmpty)
		#expect(ast.body[0].description == "2")
	}

	@Test("Parses counter") func counter() throws {
		let ast = parse("""
		makeCounter = func() {
			count = 0
			func() {
				count = count + 1
				count
			}
		}

		counter = makeCounter()
		counter()
		counter()
		""")

		#expect(ast.count == 4)
	}
}
