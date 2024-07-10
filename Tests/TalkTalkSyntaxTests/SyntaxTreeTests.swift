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
		let root = SyntaxTree.parse(source: string).root[0] as! R

		return root[keyPath: keypath] as! T
	}

	func parse<T: Syntax>(
		_ string: String,
		as _: T.Type
	) -> T {
		let root = SyntaxTree.parse(source: string).root[0]
		return root as! T
	}

	@Test("Basic") func basic() throws {
		let tree = SyntaxTree.parse(source: """
		1
		""")

		let expr = tree.root.first?
			.as(ExprStmtSyntax.self)?.expr
			.as(IntLiteralSyntax.self)

		let root = try #require(expr)
		#expect(root.position == 0)
		#expect(root.length == 1)
		#expect(root.lexeme == "1")
	}

	@Test("Unary") func unary() throws {
		let tree = SyntaxTree.parse(source: """
		-1
		""")

		let expr = tree.root.first?
			.as(ExprStmtSyntax.self)?.expr
			.as(UnaryExprSyntax.self)

		let root = try #require(expr)
		#expect(root.op.position == 0)
		#expect(root.op.length == 1)
		#expect(root.op.kind == .minus)

		let int = root.rhs.as(IntLiteralSyntax.self)!
		#expect(int.position == 1)
		#expect(int.length == 1)
		#expect(int.lexeme == "1")
	}

	@Test("Binary") func binary() throws {
		let tree = SyntaxTree.parse(source: """
		10 + 20
		""")

		let expr = tree.root.first?
			.as(ExprStmtSyntax.self)?.expr
			.as(BinaryExprSyntax.self)
		let root = try #require(expr)

		let lhs = root.lhs.cast(IntLiteralSyntax.self)
		#expect(lhs.position == 0)
		#expect(lhs.length == 2)
		#expect(lhs.lexeme == "10")

		let op = root.op
		#expect(op.position == 3)
		#expect(op.length == 1)
		#expect(op.kind == .plus)

		let rhs = root.rhs.cast(IntLiteralSyntax.self)
		#expect(rhs.position == 5)
		#expect(rhs.length == 2)
		#expect(rhs.lexeme == "20")
	}

	@Test("string literal") func string() {
		let tree = SyntaxTree.parse(source: """
		"hello world"
		""")

		let expr = tree.root[0].cast(ExprStmtSyntax.self).expr.cast(StringLiteralSyntax.self)

		#expect(expr.lexeme == #""hello world""#)
		#expect(expr.length == 13)
		#expect(expr.position == 0)
	}

	@Test("var statement") func varStmt() {
		let tree = SyntaxTree.parse(source: """
		var foo = "123"
		""")

		let decl = tree.root[0].cast(VarDeclSyntax.self)
		#expect(decl.position == 0)
		#expect(decl.length == 15)
		#expect(decl.variable.lexeme == "foo")
		#expect(decl.expr!.cast(StringLiteralSyntax.self).lexeme == #""123""#)
	}

	@Test("Group") func groupExpr() {
		let tree = SyntaxTree.parse(source: """
		(1 + 2)
		""")

		let groupExpr = tree.root[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(GroupExpr.self)

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
}
