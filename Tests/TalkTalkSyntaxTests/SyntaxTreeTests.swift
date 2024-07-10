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
		let root = SyntaxTree.parse(source: string).decls[0] as! R

		return root[keyPath: keypath] as! T
	}

	func parse<T: Syntax>(
		_ string: String,
		as _: T.Type
	) -> T {
		let root = SyntaxTree.parse(source: string).decls[0]
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
		#expect(funcDecl.parameters.position == 9)
		#expect(funcDecl.parameters.length == 0)

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
		#expect(funcDecl.parameters.position == 9)

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
		#expect(funcDecl.body.position == 11)
		#expect(funcDecl.body.length == 10)

		let exprStmt = funcDecl.body.decls[0].cast(ExprStmtSyntax.self)
		#expect(exprStmt.description == "1 + 2")
	}

	@Test("Blocks") func blocks() {
		let blockStmt = parse("""
		{
			var foo = "bar"
		}
		""", as: BlockStmtSyntax.self)

		#expect(blockStmt.position == 3)
		#expect(blockStmt.length == 17)

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
}
