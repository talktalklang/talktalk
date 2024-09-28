//
//  SubscriptsTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/20/24.
//

import TalkTalkCore
import Testing

struct SubscriptsTests {
	@Test("Array literals") func arrayLiterals() throws {
		let parsed = try Parser.parse("[1,2,3]")[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(ArrayLiteralExprSyntax.self)

		#expect(parsed.exprs.count == 3)
		#expect(parsed.exprs[0].cast(LiteralExprSyntax.self).value == .int(1))
		#expect(parsed.exprs[1].cast(LiteralExprSyntax.self).value == .int(2))
		#expect(parsed.exprs[2].cast(LiteralExprSyntax.self).value == .int(3))
	}

	@Test("Array literals with trailing comma") func arrayLiteralsWithTrailingComma() throws {
		let parsed = try Parser.parse("[1,2,3,]")[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(ArrayLiteralExprSyntax.self)

		#expect(parsed.exprs.count == 3)
		#expect(parsed.exprs[0].cast(LiteralExprSyntax.self).value == .int(1))
		#expect(parsed.exprs[1].cast(LiteralExprSyntax.self).value == .int(2))
		#expect(parsed.exprs[2].cast(LiteralExprSyntax.self).value == .int(3))
	}

	@Test("Array literals with newlines") func arrayLiteralsWithNewlines() throws {
		let parsed = try Parser.parse("""
		[
			1,
			2,
			3
		]
		""")[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(ArrayLiteralExprSyntax.self)

		#expect(parsed.exprs.count == 3)
		#expect(parsed.exprs[0].cast(LiteralExprSyntax.self).value == .int(1))
		#expect(parsed.exprs[1].cast(LiteralExprSyntax.self).value == .int(2))
		#expect(parsed.exprs[2].cast(LiteralExprSyntax.self).value == .int(3))
	}

	@Test("Array literals with newlines and trailing comma") func arrayLiteralsWithNewlinesAndTrailingComma() throws {
		let parsed = try Parser.parse("""
		[
			1,
			2,
			3,
		]
		""")[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(ArrayLiteralExprSyntax.self)

		#expect(parsed.exprs.count == 3)
		#expect(parsed.exprs[0].cast(LiteralExprSyntax.self).value == .int(1))
		#expect(parsed.exprs[1].cast(LiteralExprSyntax.self).value == .int(2))
		#expect(parsed.exprs[2].cast(LiteralExprSyntax.self).value == .int(3))
	}

	@Test("Subscript getter") func subscriptGetter() throws {
		let expr = try Parser.parse("foo[123]")[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(SubscriptExprSyntax.self)

		#expect(expr.receiver.cast(VarExprSyntax.self).name == "foo")
		#expect(expr.args.count == 1)
		#expect(expr.args[0]
			.cast(Argument.self).value
			.cast(LiteralExprSyntax.self).value == .int(123))
	}

	@Test("Subscript setter") func subscriptSetter() throws {
		let stmt = try Parser.parse("foo[123] = 456")[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(DefExprSyntax.self)

		#expect(stmt.receiver.cast(SubscriptExprSyntax.self).receiver.cast(VarExprSyntax.self).name == "foo")
		#expect(stmt.receiver.cast(SubscriptExprSyntax.self).args[0].value.cast(LiteralExprSyntax.self).value == .int(123))
		#expect(stmt.value.cast(LiteralExprSyntax.self).value == .int(456))
	}

	@Test("Array literal + subscript getter") func arrayAndSubscript() throws {
		let stmt = try Parser.parse("[1][123]")[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(SubscriptExprSyntax.self)

		#expect(stmt.receiver.cast(ArrayLiteralExprSyntax.self).exprs[0].cast(LiteralExprSyntax.self).value == .int(1))
		#expect(stmt.args[0].cast(Argument.self).value.cast(LiteralExprSyntax.self).value == .int(123))
	}
}
