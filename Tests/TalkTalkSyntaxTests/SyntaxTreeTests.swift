//
//  SyntaxTreeTests.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
import TalkTalkSyntax
import Testing

struct SyntaxTreeTests {
	func parse<T: Syntax, R: Syntax>(
		_ string: String,
		at keypath: PartialKeyPath<R>,
		as _: T.Type
	) -> T {
		let root = try! SyntaxTree.parse(source: string).decls[0] as! R

		return root[keyPath: keypath] as! T
	}

	func parse<T: Syntax>(
		_ string: String,
		as _: T.Type
	) -> T {
		let root = try! SyntaxTree.parse(source: string).decls[0]
		return root as! T
	}

	@Test("Basic") func basic() throws {
		let exprStmt = parse(
			"1",
			as: ExprStmtSyntax.self
		)

		let expr = exprStmt.expr.as(IntLiteralSyntax.self)

		let root = try #require(expr)
		#expect(root.position == 0)
		#expect(root.length == 1)
		#expect(root.lexeme == "1")
	}

	@Test("Unary") func unary() throws {
		let expr = parse(
			"-1",
			as: ExprStmtSyntax.self
		).expr.cast(UnaryExprSyntax.self)

		#expect(expr.op.position == 0)
		#expect(expr.op.length == 1)
		#expect(expr.op.kind == .minus)

		let int = expr.rhs.as(IntLiteralSyntax.self)!
		#expect(int.position == 1)
		#expect(int.length == 1)
		#expect(int.lexeme == "1")
	}

	@Test("Binary") func binary() throws {
		let expr = parse(
			"10 + 20",
			as: ExprStmtSyntax.self
		).expr.cast(BinaryExprSyntax.self)

		let lhs = expr.lhs.cast(IntLiteralSyntax.self)
		#expect(lhs.position == 0)
		#expect(lhs.length == 2)
		#expect(lhs.lexeme == "10")

		let op = expr.op
		#expect(op.position == 3)
		#expect(op.length == 1)
		#expect(op.kind == .plus)

		let rhs = expr.rhs.cast(IntLiteralSyntax.self)
		#expect(rhs.position == 5)
		#expect(rhs.length == 2)
		#expect(rhs.lexeme == "20")
	}

	@Test("string literal") func string() {
		let expr = parse(
			"""
			"hello world"
			""",
			as: ExprStmtSyntax.self
		).expr.cast(StringLiteralSyntax.self)

		#expect(expr.lexeme == #""hello world""#)
		#expect(expr.length == 13)
		#expect(expr.position == 0)
	}

	@Test("var statement") func varStmt() {
		let decl = parse(
			"""
			var foo = "123"
			""",
			as: VarDeclSyntax.self
		)

		#expect(decl.position == 0)
		#expect(decl.length == 15)
		#expect(decl.variable.lexeme == "foo")
		#expect(decl.expr!.cast(StringLiteralSyntax.self).lexeme == #""123""#)
	}

	@Test("var statement with type") func varStmtWithType() {
		let decl = parse(
			"""
			var foo: Int = 123
			""",
			as: VarDeclSyntax.self
		)

		#expect(decl.position == 0)
		#expect(decl.length == 18)
		#expect(decl.variable.lexeme == "foo")
		#expect(decl.typeDecl!.name.cast(IdentifierSyntax.self).lexeme == "Int")
		#expect(decl.expr!.cast(IntLiteralSyntax.self).lexeme == "123")
	}

	@Test("Group") func groupExpr() {
		let groupExpr = parse(
			"""
			(1 + 2)
			""",
			as: ExprStmtSyntax.self
		).expr.cast(GroupExpr.self)

		#expect(groupExpr.position == 0)
		#expect(groupExpr.length == 7)
		#expect(
			groupExpr.expr.cast(BinaryExprSyntax.self).description == parse(
				"1 + 2",
				at: \ExprStmtSyntax.expr,
				as: BinaryExprSyntax.self
			).description
		)
	}

	@Test("Empty function") func function() {
		let funcDecl = parse("""
		func foo() {}
		""", as: FunctionDeclSyntax.self)

		#expect(funcDecl.position == 0)
		#expect(funcDecl.length == 13)

		#expect(funcDecl.name.position == 5)
		#expect(funcDecl.name.length == 3)
		#expect(funcDecl.name.description == "foo")

		#expect(funcDecl.parameters.isEmpty)
		#expect(funcDecl.parameters.position == 8)
		#expect(funcDecl.parameters.length == 2)

		#expect(funcDecl.body.isEmpty)
		#expect(funcDecl.body.position == 11)
		#expect(funcDecl.body.length == 2)
	}

	@Test("Function parameters") func functionParameters() {
		let funcDecl = parse("""
		func foo(bar) {}
		""", as: FunctionDeclSyntax.self)

		#expect(funcDecl.position == 0)
		#expect(funcDecl.length == 16)

		#expect(funcDecl.name.position == 5)
		#expect(funcDecl.name.length == 3)
		#expect(funcDecl.name.description == "foo")

		#expect(funcDecl.parameters.count == 1)
		#expect(funcDecl.parameters.position == 8)

		let param = funcDecl.parameters[0]
		#expect(param.position == 9)
		#expect(param.length == 3)
		#expect(param.lexeme == "bar")

		#expect(funcDecl.body.isEmpty)
		#expect(funcDecl.body.position == 14)
		#expect(funcDecl.body.length == 2)
	}

	@Test("Function Body") func functionBody() {
		let funcDecl = parse("""
		func foo() {
			1 + 2
		}
		""", as: FunctionDeclSyntax.self)

		#expect(funcDecl.position == 0)
		#expect(funcDecl.length == 21)

		#expect(funcDecl.name.position == 5)
		#expect(funcDecl.name.length == 3)
		#expect(funcDecl.name.description == "foo")

		#expect(funcDecl.parameters.isEmpty)

		#expect(funcDecl.body.decls.count == 1)
		#expect(funcDecl.body.position == 11)
		#expect(funcDecl.body.length == 10)

		let exprStmt = funcDecl.body.decls[0].cast(ExprStmtSyntax.self)
		#expect(exprStmt.description == "1 + 2")
	}

	@Test("Function with type") func functionWithType() {
		let funcDecl = parse("""
		func foo() -> Int {
			1 + 2
		}
		""", as: FunctionDeclSyntax.self)

		#expect(funcDecl.position == 0)
		#expect(funcDecl.length == 28)

		#expect(funcDecl.name.position == 5)
		#expect(funcDecl.name.length == 3)
		#expect(funcDecl.name.description == "foo")

		#expect(funcDecl.typeDecl?.name.lexeme == "Int")

		#expect(funcDecl.parameters.isEmpty)

		#expect(funcDecl.body.decls.count == 1)
		#expect(funcDecl.body.position == 18)
		#expect(funcDecl.body.length == 10)
	}

	@Test("Gross Function Body Formatting") func functionGrossBody() {
		let funcDecl = parse("""
		func foo()
		{
			1 + 2
		}
		""", as: FunctionDeclSyntax.self)

		#expect(funcDecl.position == 0)
		#expect(funcDecl.length == 21)

		#expect(funcDecl.name.position == 5)
		#expect(funcDecl.name.length == 3)
		#expect(funcDecl.name.description == "foo")

		#expect(funcDecl.parameters.isEmpty)

		#expect(funcDecl.body.decls.count == 1)
		#expect(funcDecl.body.position == 10)
		#expect(funcDecl.body.length == 11)

		let exprStmt = funcDecl.body.decls[0].cast(ExprStmtSyntax.self)
		#expect(exprStmt.description == "1 + 2")
	}

	@Test("Blocks") func blocks() {
		let blockStmt = parse("""
		{
			var foo = "bar"
		}
		""", as: BlockStmtSyntax.self)

		#expect(blockStmt.position == 0)
		#expect(blockStmt.length == 20)

		let decl = blockStmt.decls[0].cast(VarDeclSyntax.self)
		#expect(decl.length == 15)
		#expect(decl.variable.lexeme == "foo")
		#expect(decl.variable.position == 7)

		#expect(blockStmt.description == """
		{
			var foo = "bar"
		}
		""")
	}

	@Test("Call expression") func call() {
		let callExpr = parse(
			"""
			foo()
			""",
			at: \ExprStmtSyntax.expr,
			as: CallExprSyntax.self
		)

		#expect(callExpr.position == 3)
		#expect(callExpr.length == 2)

		#expect(callExpr.callee.cast(VariableExprSyntax.self).name.lexeme == "foo")
		#expect(callExpr.arguments.isEmpty)
	}

	@Test("Call expression with args") func callWithArgs() {
		let callExpr = parse(
			"""
			foo(1 + 2)
			""",
			at: \ExprStmtSyntax.expr,
			as: CallExprSyntax.self
		)

		#expect(callExpr.position == 3)
		#expect(callExpr.length == 7)

		#expect(callExpr.callee.cast(VariableExprSyntax.self).name.lexeme == "foo")

		let argExpr = callExpr.arguments[0].cast(BinaryExprSyntax.self)
		#expect(argExpr.description == "1 + 2")
	}

	@Test("Nested calls") func nestedCalls() {
		let call = parse(
			"""
			print(foo(n))
			""",
			at: \ExprStmtSyntax.expr,
			as: CallExprSyntax.self
		)

		#expect(call.callee.cast(VariableExprSyntax.self).name.lexeme == "print")

		let inner = call.arguments[0].cast(CallExprSyntax.self)
		#expect(inner.callee.cast(VariableExprSyntax.self).name.lexeme == "foo")
	}

	@Test("Order of operations") func orderOfOperations() {
		let expr = parse(
			"1 + 2 * 3",
			at: \ExprStmtSyntax.expr,
			as: BinaryExprSyntax.self
		)

		let lhs = expr.lhs.cast(IntLiteralSyntax.self)
		#expect(lhs.lexeme == "1")
		#expect(expr.op.kind == .plus)

		let rhs = expr.rhs.cast(BinaryExprSyntax.self)
		#expect(rhs.description == "2 * 3")
	}

	@Test("If statement") func ifStatement() {
		let expr = parse(
			"""
			if 1 < 2 {
				3
			}
			""",
			as: IfStmtSyntax.self
		)

		#expect(expr.position == 0)
		#expect(expr.length == 15)

		#expect(expr.condition.description == "1 < 2")
		#expect(expr.body.description == """
		{
			3
		}
		""")
	}

	@Test("while statement") func whileStatement() {
		let expr = parse(
			"""
			while 1 < 2 {
				3
			}
			""",
			as: WhileStmtSyntax.self
		)

		#expect(expr.position == 0)
		#expect(expr.length == 18)

		#expect(expr.condition.description == "1 < 2")
		#expect(expr.body.description == """
		{
			3
		}
		""")
	}

	@Test("Return statement") func returnStatement() {
		let expr = parse(
			"""
			func foo() { return "bar" }
			""",
			at: \FunctionDeclSyntax.body.decls[0],
			as: ReturnStmtSyntax.self
		)

		#expect(expr.position == 13)
		#expect(expr.length == 12)
		#expect(expr.value.description == #""bar""#)
		#expect(expr.description == """
		return "bar"
		""")
	}

	@Test("Assignment") func assignment() {
		let expr = parse(
			"a = 123",
			at: \ExprStmtSyntax.expr,
			as: AssignmentExpr.self
		)

		#expect(expr.lhs.cast(VariableExprSyntax.self).name.lexeme == "a")
		#expect(expr.rhs.cast(IntLiteralSyntax.self).lexeme == "123")
	}

	@Test("Literals") func literals() {
		let t = parse("true", at: \ExprStmtSyntax.expr, as: LiteralExprSyntax.self)
		let f = parse("false", at: \ExprStmtSyntax.expr, as: LiteralExprSyntax.self)
		let n = parse("nil", at: \ExprStmtSyntax.expr, as: LiteralExprSyntax.self)

		#expect(t.kind == .true)
		#expect(f.kind == .false)
		#expect(n.kind == .nil)
	}

	@Test("&&") func and() {
		let expr = parse(
			"""
			true && false
			""",
			at: \ExprStmtSyntax.expr,
			as: BinaryExprSyntax.self
		)

		#expect(expr.lhs.cast(LiteralExprSyntax.self).kind == .true)
		#expect(expr.op.kind == .andAnd)
		#expect(expr.rhs.cast(LiteralExprSyntax.self).kind == .false)
	}

	@Test("||") func or() {
		let expr = parse(
			"""
			true || false
			""",
			at: \ExprStmtSyntax.expr,
			as: BinaryExprSyntax.self
		)

		#expect(expr.lhs.cast(LiteralExprSyntax.self).kind == .true)
		#expect(expr.op.kind == .pipePipe)
		#expect(expr.rhs.cast(LiteralExprSyntax.self).kind == .false)
	}

	@Test("Basic class") func basicClass() {
		let expr = parse(
			"""
			class Person {}
			""",
			as: ClassDeclSyntax.self
		)

		#expect(expr.name.cast(IdentifierSyntax.self).lexeme == "Person")
		#expect(expr.body.isEmpty)
	}

	@Test("Class methods") func classMethods() {
		let expr = parse(
			"""
			class Person {
				func foo() {
					print("foo")
				}

				func bar() {
					print("bar")
				}
			}
			""",
			as: ClassDeclSyntax.self
		)

		#expect(expr.name.cast(IdentifierSyntax.self).lexeme == "Person")
		#expect(expr.body.decls.count == 2)
	}

	@Test("Class properties") func classProperties() {
		let expr = parse(
			"""
			class Person {
				var age: Int
			}
			""",
			as: ClassDeclSyntax.self
		)

		#expect(expr.name.cast(IdentifierSyntax.self).lexeme == "Person")
		#expect(expr.body.decls.count == 1)

		let prop = expr.body.decls[0].cast(PropertyDeclSyntax.self)
		#expect(prop.name.lexeme == "age")
		#expect(prop.typeDecl.name.lexeme == "Int")
	}

	@Test("Class properties with default value") func classPropertiesWithDefault() {
		let expr = parse(
			"""
			class Person {
				var age: Int = 123
			}
			""",
			as: ClassDeclSyntax.self
		)

		#expect(expr.name.cast(IdentifierSyntax.self).lexeme == "Person")
		#expect(expr.body.decls.count == 1)

		let prop = expr.body.decls[0].cast(PropertyDeclSyntax.self)
		#expect(prop.name.lexeme == "age")
		#expect(prop.typeDecl.name.lexeme == "Int")
		#expect(prop.value!.cast(IntLiteralSyntax.self).lexeme == "123")
	}

	@Test("Class init") func classInit() {
		let expr = parse(
			"""
			class Person {
				init() {
					print("foo")
				}

				func bar() {
					print("bar")
				}
			}
			""",
			as: ClassDeclSyntax.self
		)

		ASTFormatter.print(expr)

		#expect(expr.name.cast(IdentifierSyntax.self).lexeme == "Person")
		#expect(expr.body.decls.count == 2)
		#expect(expr.body.decls[0].cast(InitDeclSyntax.self).position == 16)
		#expect(expr.body.decls[1].cast(FunctionDeclSyntax.self).name.lexeme == "bar")
	}

	@Test("Error when trying to init all willy nill") func classBadInit() {
		let expr = parse(
			"""
			init() {
				// This doesn't work
			}
			""",
			as: ErrorSyntax.self
		)

		#expect(expr.position == 0)
	}

	@Test("self") func testSelf() {
		let fn = parse(
			"""
			class Person {
				func foo() {
					self
				}
			}
			""",
			at: \ClassDeclSyntax.body.decls[0],
			as: FunctionDeclSyntax.self
		)

		let expr = fn.body.decls[0].cast(ExprStmtSyntax.self).expr.cast(VariableExprSyntax.self)

		#expect(expr.position == 31)
		#expect(expr.length == 4)
		#expect(expr.name.lexeme == "self")
	}

	@Test("super") func testSuper() {
		let fn = parse(
			"""
			class Person {
				func foo() {
					super
				}
			}
			""",
			at: \ClassDeclSyntax.body.decls[0],
			as: FunctionDeclSyntax.self
		)

		let expr = fn.body.decls[0].cast(ExprStmtSyntax.self).expr.cast(VariableExprSyntax.self)

		#expect(expr.position == 31)
		#expect(expr.length == 5)
		#expect(expr.name.lexeme == "super")
	}

	@Test("Get property") func getProperty() {
		let expr = parse(
			"""
			foo.bar
			""",
			at: \ExprStmtSyntax.expr,
			as: PropertyAccessExpr.self
		)

		#expect(expr.position == 0)
		#expect(expr.length == 7)
		#expect(expr.receiver.cast(VariableExprSyntax.self).name.lexeme == "foo")
		#expect(expr.property.cast(IdentifierSyntax.self).lexeme == "bar")
		#expect(ASTFormatter.format(expr) == "foo.bar")
	}

	@Test("Set property") func setProperty() {
		let expr = parse(
			"""
			foo.bar = 123
			""",
			at: \ExprStmtSyntax.expr,
			as: AssignmentExpr.self
		)

		#expect(expr.position == 0)
		#expect(expr.length == 13)
		#expect(expr.lhs.cast(PropertyAccessExpr.self).receiver.cast(VariableExprSyntax.self).name.lexeme == "foo")

		#expect(expr.rhs.cast(IntLiteralSyntax.self).lexeme == "123")
		#expect(ASTFormatter.format(expr) == "foo.bar = 123")
	}

	@Test("Call property") func callProperty() {
		let expr = parse(
			"""
			foo.bar(123)
			""",
			at: \ExprStmtSyntax.expr,
			as: CallExprSyntax.self
		)

		#expect(expr.position == 0)
		#expect(expr.length == 12)

		#expect(expr.callee.cast(PropertyAccessExpr.self).receiver.cast(VariableExprSyntax.self).name.lexeme == "foo")
		#expect(expr.callee.cast(PropertyAccessExpr.self).property.lexeme == "bar")
		#expect(expr.arguments[0].cast(IntLiteralSyntax.self).lexeme == "123")
		#expect(ASTFormatter.format(expr) == "foo.bar(123)")
	}

	@Test("Array literal syntax") func arrayLiteral() {
		let expr = parse(
			"""
			[1, 2, 3]
			""",
			at: \ExprStmtSyntax.expr,
			as: ArrayLiteralSyntax.self
		)

		#expect(expr.position == 0)
		#expect(expr.length == 9)
		#expect(expr.description == "[1, 2, 3]")
	}
}
