//
//  SyntaxTreeTests.swift
//  
//
//  Created by Pat Nakajima on 7/8/24.
//
import TalkTalkSyntax
import Testing

struct SyntaxTreeTests {
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
}
