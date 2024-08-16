//
//  ParserTests.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

@testable import TalkTalkSyntax
import Testing

@MainActor
struct TalkTalkParserTests {
	func parse(_ source: String, errors: [SyntaxError] = []) -> [Syntax] {
		let lexer = TalkTalkLexer(.init(path: "", text: source))
		var parser = Parser(lexer)
		let result = parser.parse()

		if errors.isEmpty {
			#expect(parser.errors.isEmpty)
		} else if errors.count == parser.errors.count {
			for (i, error) in parser.errors.enumerated() {
				#expect(errors[i] == error)
			}
		} else {
			#expect(parser.errors == errors)
		}

		return result
	}

	@Test("Doesn't return an error on a blank file") func blank() {
		let lexer = TalkTalkLexer(.init(path: "", text: """

		\("   " /* whitespace */ )
		"""))
		var parser = Parser(lexer)
		_ = parser.parse()

		#expect(parser.errors.isEmpty)
	}

	@Test("Imports") func imports() throws {
		let parsed = parse("""
		import Test
		""")[0].cast(ImportStmtSyntax.self)

		#expect(parsed.token.lexeme == "import")
		#expect(parsed.module.name == "Test")
	}

	@Test("Literals") func literals() throws {
		#expect(parse("1")[0].cast(ExprStmtSyntax.self).expr.cast(LiteralExprSyntax.self).value == .int(1))
		#expect(parse("true")[0].cast(ExprStmtSyntax.self).expr.cast(LiteralExprSyntax.self).value == .bool(true))
		#expect(parse("false")[0].cast(ExprStmtSyntax.self).expr.cast(LiteralExprSyntax.self).value == .bool(false))
		#expect(parse(#""hello world""#)[0].cast(ExprStmtSyntax.self).expr.cast(LiteralExprSyntax.self).value == .string("hello world"))
	}

	@Test("Don't crash on incomplete string") func incompleteString() throws {
		#expect(parse(#""hello "#, errors: [
			SyntaxError(
				line: 0,
				column: 7,
				kind: .lexerError("unterminated string literal")
				)
			])[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(LiteralExprSyntax.self).value == .string("hello"))
	}

	@Test("Plus expr") func binaryexpr() throws {
		let ast = parse("1 + 2")[0].cast(ExprStmtSyntax.self).expr
		let expr = try #require(ast as? BinaryExpr)
		#expect(expr.lhs.description == "1")
		#expect(expr.rhs.description == "2")
		#expect(expr.op == .plus)
	}

	@Test("Comparison expr") func comparisonexpr() throws {
		#expect(parse("1 < 2")[0].description == "1 < 2")
	}

	@Test("Equality expr") func equalityexpr() throws {
		let ast = parse("1 == 2")[0].cast(ExprStmtSyntax.self).expr
		let expr = try #require(ast as? BinaryExpr)
		#expect(expr.lhs.description == "1")
		#expect(expr.rhs.description == "2")
		#expect(expr.op == .equalEqual)
	}

	@Test("Not equality expr") func notequalityexpr() throws {
		let ast = parse("1 != 2")[0].cast(ExprStmtSyntax.self).expr
		let expr = try #require(ast as? BinaryExpr)
		#expect(expr.lhs.description == "1")
		#expect(expr.rhs.description == "2")
		#expect(expr.op == .bangEqual)
	}

	@Test("def expr") func def() {
		let ast = parse("foo = 123")[0].cast(ExprStmtSyntax.self).expr as! DefExpr
		#expect(ast.receiver.cast(VarExprSyntax.self).name == "foo")
		#expect(ast.value.cast(LiteralExprSyntax.self).value == .int(123))
	}

	@Test("Grouped expr") func grouped() {
		let ast = parse("(123)")[0].cast(ExprStmtSyntax.self).expr as! LiteralExprSyntax
		#expect(ast.value == .int(123))
	}

	@Test("Newlines terminate statements") func newlineTerminateStatement() {
		let ast = parse("""
		func() {
			self.foo = hello + 1
			(hello + 1)
		}
		""")[0].cast(FuncExprSyntax.self).body.exprs

		print(ast.description)

		let defExpr = ast[0].cast(ExprStmtSyntax.self).expr.cast(DefExprSyntax.self)
		#expect(defExpr.receiver.description == "self.foo")
		#expect(defExpr.value.description == "hello + 1")
		#expect(ast[1].cast(ExprStmtSyntax.self).expr.cast(BinaryExprSyntax.self).description == "hello + 1")
		#expect(ast.count == 2)
	}

	@Test("var/let decls") func varLetDecls() {
		let a = parse("var foo = 123")[0].cast(VarDeclSyntax.self)
		#expect(a.name == "foo")
		#expect(a.typeDecl == nil)
		#expect(a.value?.cast(LiteralExprSyntax.self).value == .int(123))

		let b = parse("var foo: int")[0].cast(VarDeclSyntax.self)
		#expect(b.name == "foo")
		#expect(b.typeDecl == "int")
		#expect(b.value == nil)

		let c = parse("var foo: int = 123")[0].cast(VarDeclSyntax.self)
		#expect(c.name == "foo")
		#expect(c.typeDecl == "int")
		#expect(c.value?.cast(LiteralExprSyntax.self).value == .int(123))

		let d = parse("let foo = 123")[0].cast(LetDeclSyntax.self)
		#expect(d.name == "foo")
		#expect(d.typeDecl == nil)
		#expect(d.value?.cast(LiteralExprSyntax.self).value == .int(123))

		let e = parse("let foo: int")[0].cast(LetDeclSyntax.self)
		#expect(e.name == "foo")
		#expect(e.typeDecl == "int")
		#expect(e.value == nil)

		let f = parse("let foo: int = 123")[0].cast(LetDeclSyntax.self)
		#expect(f.name == "foo")
		#expect(f.typeDecl == "int")
		#expect(f.value?.cast(LiteralExprSyntax.self).value == .int(123))
	}

	@Test("multiple statements") func multiple() {
		let ast = parse("""
		(1)
		(2)
		sum = 1 + 2
		""")[2].cast(ExprStmtSyntax.self).expr as! DefExpr
		#expect(ast.receiver.cast(VarExprSyntax.self).name == "sum")
		#expect(ast.value.cast(BinaryExprSyntax.self).op == .plus)
	}

	@Test("if stmt") func ifStmt() {
		let ast = parse("""
		if true {
			1
		} else {
			2
		}
		""")[0].cast(IfStmtSyntax.self)
		#expect(ast.condition.description == "true")
		#expect(ast.consequence.exprs[0].description == "1")
		#expect(ast.alternative?.exprs[0].description == "2")
	}

	@Test("if expr") func ifExpr() {
		let ast = parse("""
		a = if true {
			1
		} else {
			2
		}
		""")[0].cast(ExprStmtSyntax.self).expr.cast(DefExprSyntax.self)
		let ifExpr = ast.value.cast(IfExprSyntax.self)

		#expect(ifExpr.condition.description == "true")
		#expect(ifExpr.consequence.exprs[0].description == "1")
		#expect(ifExpr.alternative.exprs[0].description == "2")
	}

	@Test("while expr") func whileexpr() {
		let ast = parse("""
		while i < 5 {
			123
			456
		}
		""")[0].cast(WhileStmtSyntax.self)
		#expect(ast.condition.description == "i < 5")
		#expect(ast.body.exprs[0].cast(ExprStmtSyntax.self).expr.cast(LiteralExprSyntax.self).value == .int(123))
	}
	

	@Test("func expr") func funcexpr() throws {
		let ast = parse("""
		func(x, y) { x + y }
		""")[0]
		let fn = try #require(ast as? FuncExpr)
		#expect(fn.params.params[0].name == "x")
		#expect(fn.params.params[1].name == "y")

		let bodyExpr = fn.body.exprs[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(BinaryExprSyntax.self)

		#expect(bodyExpr.lhs.description == "x")
		#expect(bodyExpr.rhs.description == "y")
		#expect(bodyExpr.op == .plus)
	}

	@Test("return expr") func returnExpr() throws {
		let ast = parse("""
		func() {
			return x
		}
		""")[0]

		let fn = try #require(ast as? FuncExpr)
		#expect(fn.body.exprs[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(ReturnExprSyntax.self).value?.description == "x")
	}

	@Test("named func expr") func namedfuncexpr() throws {
		let ast = parse("""
		func foo(x, y) { x + y }
		""")[0]
		let fn = try #require(ast as? FuncExpr)
		#expect(fn.name?.lexeme == "foo")
		#expect(fn.params.params[0].name == "x")
		#expect(fn.params.params[1].name == "y")

		let bodyExpr = fn.body.exprs[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(BinaryExprSyntax.self)
		#expect(bodyExpr.lhs.description == "x")
		#expect(bodyExpr.rhs.description == "y")
		#expect(bodyExpr.op == .plus)
	}

	@Test("call expr") func callExpr() {
		let ast = parse("""
		foo(1)
		""")[0].cast(ExprStmtSyntax.self).expr as! CallExpr
		#expect(ast.location.start.column == 0)
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
		""")[0]
		let funcExpr = ast.cast(FuncExprSyntax.self)
		#expect(funcExpr.params.params.isEmpty)
		#expect(funcExpr.body.exprs[0].description == "2")
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

		let structExpr = ast[0].cast(StructDeclSyntax.self)
		#expect(structExpr.name == "Foo")

		let varDecl = structExpr.body.decls[0].cast(VarDeclSyntax.self)
		#expect(varDecl.name == "age")
		#expect(varDecl.typeDecl == "i32")

		let fooDef = ast[1].cast(ExprStmtSyntax.self).expr.cast(DefExprSyntax.self)
		#expect(fooDef.receiver.cast(VarExprSyntax.self).name == "foo")

		let fooInit = fooDef.value.cast(CallExprSyntax.self)
		#expect(fooInit.callee.description == "Foo")
		#expect(fooInit.args[0].label == "age")
		#expect(fooInit.args[0].value.cast(LiteralExprSyntax.self).value == .int(123))

		let fooMember = ast[2].cast(ExprStmtSyntax.self).expr.cast(MemberExprSyntax.self)
		#expect(fooMember.receiver.cast(VarExprSyntax.self).name == "foo")
		#expect(fooMember.property == "age")
	}

	@Test("Parses struct with let decl") func structsLet() throws {
		let ast = parse("""
		struct Foo {
			let age: i32

			init(age: i32) {
				self.age = age
			}
		}

		foo = Foo(age: 123)
		foo.age
		""")

		let structExpr = ast[0].cast(StructDeclSyntax.self)
		#expect(structExpr.name == "Foo")

		let varDecl = structExpr.body.decls[0].cast(LetDeclSyntax.self)
		#expect(varDecl.name == "age")
		#expect(varDecl.typeDecl == "i32")

		let fooDef = ast[1].cast(ExprStmtSyntax.self).expr.cast(DefExprSyntax.self)
		#expect(fooDef.receiver.cast(VarExprSyntax.self).name == "foo")

		let fooInit = fooDef.value.cast(CallExprSyntax.self)
		#expect(fooInit.callee.description == "Foo")
		#expect(fooInit.args[0].label == "age")
		#expect(fooInit.args[0].value.cast(LiteralExprSyntax.self).value == .int(123))

		let fooMember = ast[2].cast(ExprStmtSyntax.self).expr.cast(MemberExprSyntax.self)
		#expect(fooMember.receiver.cast(VarExprSyntax.self).name == "foo")
		#expect(fooMember.property == "age")
	}

	@Test("Generics?") func generics() throws {
		let ast = parse("""
		struct Foo<Bar> {
			var fizz: Bar
		}

		Foo<int>()
		""")

		let structExpr = ast[0].cast(StructDeclSyntax.self)
		#expect(structExpr.name == "Foo")
		#expect(structExpr.genericParams?.params.map(\.name) == ["Bar"])

		let calleeExpr = try #require(ast[1].cast(ExprStmtSyntax.self).expr.cast(CallExprSyntax.self).callee.as(TypeExprSyntax.self))
		#expect(calleeExpr.identifier.lexeme == "Foo")
		#expect(calleeExpr.genericParams?.params.map(\.name) == ["int"])
	}

	@Test("Parses bang") func bang() throws {
		let expr = try #require(parse("!hello")[0].cast(ExprStmtSyntax.self).expr as? UnaryExpr)
		#expect(expr.op == .bang)
		#expect(expr.expr.cast(VarExprSyntax.self).name == "hello")
	}

	@Test("Parses negative") func negative() throws {
		let expr = try #require(parse("-123")[0].cast(ExprStmtSyntax.self).expr as? UnaryExpr)
		#expect(expr.op == .minus)
		#expect(expr.expr.cast(LiteralExprSyntax.self).value == .int(123))
	}

	@Test("Parses assignment with property access") func assignmentWithProp() throws {
		let ast = parse("""
		newCapacity = self.capacity * 2
		""")

		let defExpr = ast[0].cast(ExprStmtSyntax.self).expr.cast(DefExprSyntax.self)
		#expect(defExpr.receiver.as(VarExprSyntax.self)?.name == "newCapacity")
		let value = defExpr.value.cast(BinaryExprSyntax.self)
		let lhs = try #require(value.lhs.as(MemberExprSyntax.self))
		let rhs = try #require(value.rhs.as(LiteralExprSyntax.self))
		let op = value.op
		#expect(op == .star)
		#expect(lhs.property == "capacity")
		#expect(lhs.receiver.as(VarExprSyntax.self)?.name == "self")
		#expect(rhs.value == .int(2))
	}
}
