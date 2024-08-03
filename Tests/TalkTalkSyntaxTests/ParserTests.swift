//
//  ParserTests.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax
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
		#expect(parse(#""hello world""#)[0].cast(LiteralExprSyntax.self).value == .string("hello world"))
	}

	@Test("Plus expr") func binaryexpr() throws {
		let ast = parse("1 + 2")[0]
		let expr = try #require(ast as? BinaryExpr)
		#expect(expr.lhs.description == "1")
		#expect(expr.rhs.description == "2")
		#expect(expr.op == .plus)
	}

	@Test("Comparison expr") func comparisonexpr() throws {
		#expect(parse("1 < 2")[0].description == "1 < 2")
	}

	@Test("Equality expr") func equalityexpr() throws {
		let ast = parse("1 == 2")[0]
		let expr = try #require(ast as? BinaryExpr)
		#expect(expr.lhs.description == "1")
		#expect(expr.rhs.description == "2")
		#expect(expr.op == .equalEqual)
	}

	@Test("Not equality expr") func notequalityexpr() throws {
		let ast = parse("1 != 2")[0]
		let expr = try #require(ast as? BinaryExpr)
		#expect(expr.lhs.description == "1")
		#expect(expr.rhs.description == "2")
		#expect(expr.op == .bangEqual)
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
		#expect(ast.consequence.exprs[0].description == "1")
		#expect(ast.alternative.exprs[0].description == "2")
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
		#expect(fn.body.exprs[0].cast(BinaryExprSyntax.self).lhs.description == "x")
		#expect(fn.body.exprs[0].cast(BinaryExprSyntax.self).rhs.description == "y")
		#expect(fn.body.exprs[0].cast(BinaryExprSyntax.self).op == .plus)
	}

	@Test("return expr") func returnExpr() throws {
		let ast = parse("""
		func() {
			return x
		}
		""")[0]

		let fn = try #require(ast as? FuncExpr)
		#expect(fn.body.exprs[0].cast(ReturnExprSyntax.self).value?.description == "x")
	}

	@Test("named func expr") func namedfuncexpr() throws {
		let ast = parse("""
		func foo(x, y) { x + y }
		""")[0]
		let fn = try #require(ast as? FuncExpr)
		#expect(fn.name == "foo")
		#expect(fn.params.params[0].name == "x")
		#expect(fn.params.params[1].name == "y")
		#expect(fn.body.exprs[0].cast(BinaryExprSyntax.self).lhs.description == "x")
		#expect(fn.body.exprs[0].cast(BinaryExprSyntax.self).rhs.description == "y")
		#expect(fn.body.exprs[0].cast(BinaryExprSyntax.self).op == .plus)
	}

	@Test("call expr") func callExpr() {
		let ast = parse("""
		foo(1)
		""")[0] as! CallExpr
		#expect(ast.callee.description == "foo")
		#expect(ast.args[0].value.description == "1")
	}

	@Test("passing an inline func to a func call") func inlineInlineCall() {
		let ast = parse("""
		func(x) { x }(func(y) { y })
		""")[0] as! CallExpr
		#expect(ast.callee.cast(FuncExprSyntax.self).params.params[0].name == "x")
		#expect(ast.args[0].value.cast(FuncExprSyntax.self).params.params[0].name == "y")
	}

	@Test("Func with no params") func noparams() {
		let ast = parse("""
		func() { 2 }
		""")[0] as! FuncExpr
		#expect(ast.params.params.isEmpty)
		#expect(ast.body.exprs[0].description == "2")
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

	@Test("Parses struct") func structs() throws {
		let ast = parse("""
		struct Foo {
			var age: i32
		}

		foo = Foo(age: 123)
		foo.age
		""")

		let structExpr = ast[0].cast(StructExprSyntax.self)
		#expect(structExpr.name == "Foo")

		let varDecl = structExpr.body.decls[0].cast(VarDeclSyntax.self)
		#expect(varDecl.name == "age")
		#expect(varDecl.typeDecl == "i32")

		let fooDef = ast[1].cast(DefExprSyntax.self)
		#expect(fooDef.name.lexeme == "foo")

		let fooInit = fooDef.value.cast(CallExprSyntax.self)
		#expect(fooInit.callee.description == "Foo")
		#expect(fooInit.args[0].label == "age")
		#expect(fooInit.args[0].value.cast(LiteralExprSyntax.self).value == .int(123))

		let fooMember = ast[2].cast(MemberExprSyntax.self)
		#expect(fooMember.receiver.cast(VarExprSyntax.self).name == "foo")
		#expect(fooMember.property == "age")
	}

	@Test("Parses struct with let decl") func structsLet() throws {
		let ast = parse("""
		struct Foo {
			let age: i32
		}

		foo = Foo(age: 123)
		foo.age
		""")

		let structExpr = ast[0].cast(StructExprSyntax.self)
		#expect(structExpr.name == "Foo")

		let varDecl = structExpr.body.decls[0].cast(LetDeclSyntax.self)
		#expect(varDecl.name == "age")
		#expect(varDecl.typeDecl == "i32")

		let fooDef = ast[1].cast(DefExprSyntax.self)
		#expect(fooDef.name.lexeme == "foo")

		let fooInit = fooDef.value.cast(CallExprSyntax.self)
		#expect(fooInit.callee.description == "Foo")
		#expect(fooInit.args[0].label == "age")
		#expect(fooInit.args[0].value.cast(LiteralExprSyntax.self).value == .int(123))

		let fooMember = ast[2].cast(MemberExprSyntax.self)
		#expect(fooMember.receiver.cast(VarExprSyntax.self).name == "foo")
		#expect(fooMember.property == "age")
	}

	@Test("Parses bang") func bang() throws {
		let expr = try #require(parse("!hello")[0] as? UnaryExpr)
		#expect(expr.op == .bang)
		#expect(expr.expr.cast(VarExprSyntax.self).name == "hello")
	}

	@Test("Parses negative") func negative() throws {
		let expr = try #require(parse("-123")[0] as? UnaryExpr)
		#expect(expr.op == .minus)
		#expect(expr.expr.cast(LiteralExprSyntax.self).value == .int(123))
	}
}
