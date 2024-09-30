//
//  OptionalsTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/17/24.
//
import TalkTalkCore
import Testing
@testable import TypeChecker

struct OptionalsTest: TypeCheckerTest {
	@Test("Can infer optional") func basic() throws {
		let syntax = try Parser.parse(
			"""
			var foo: int?

			foo

			match foo {
			case .some(let val):
				val
			case .none:
				123
			}
			"""
		)

		let context = try infer(syntax)
		let optionalType = context[syntax[1]]!
		#expect(optionalType == .type(.optional(.base(.int))))

		let unwrapped = syntax[2]
			.cast(MatchStatementSyntax.self).cases[0].body[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(VarExprSyntax.self)

		#expect(context[unwrapped] == .type(.base(.int)))
	}

	@Test("Returning value") func returningValue() throws {
		let syntax = try Parser.parse(
			"""
			func maybe(on: bool) -> int? {
				if on {
					return 123
				} else {
					return none
				}
			}

			maybe(true)
			"""
		)

		let context = try infer(syntax)
		let optionalType = context[syntax[1]]!
	}

	@Test("Can match subscripts") func subs() throws {
		let syntax = try Parser.parse(
			"""
			let a: Array<String?> = ["foo"]
			let b = a[2]

			match b {
			case .some(let val):
				return val
			case .none:
				return nil
			}
			"""
		)

		let context = try infer(syntax)
		let valSyntax = syntax[2]
			.cast(MatchStatementSyntax.self).cases[0].body[0]
			.cast(ReturnStmtSyntax.self).value!
			.cast(VarExprSyntax.self)

		#expect(context[valSyntax] == .type(.base(.string)))
	}

	@Test("Can let unwrap") func letUnwrap() throws {
		let syntax = try Parser.parse(
			"""
			var foo: Array<int?> = []
			var bar = foo[1]

			bar

			if let bar {
				bar
			}
			"""
		)

		let context = try infer(syntax, verbose: true)

		#expect(context[syntax[2]] == .type(.optional(.base(.int))))

		let varExpr = syntax[3]
			.cast(IfStmtSyntax.self).consequence.stmts[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(VarExprSyntax.self)

		#expect(context[varExpr] == .type(.base(.int)))
	}

	@Test("let unwrap does not leak into else scope") func letUnwrapDoesNotLeak() throws {
		let syntax = try Parser.parse(
			"""
			var foo: Array<int?> = []
			var bar = foo[1]

			bar

			if let bar {
				bar
			} else {
				bar
			}
			"""
		)

		let context = try infer(syntax,verbose: true)

		#expect(context[syntax[2]] == .type(.optional(.base(.int))))

		let varExpr = syntax[3]
			.cast(IfStmtSyntax.self).alternative!.stmts[0]
			.cast(ExprStmtSyntax.self).expr
			.cast(VarExprSyntax.self)

		print()

		#expect(context[varExpr] == .type(.optional(.base(.int))))
	}
}
