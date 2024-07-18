//
//  TypedValueTests.swift
//
//
//  Created by Pat Nakajima on 7/13/24.
//
import TalkTalkSyntax
@testable import TalkTalkTyper
import Testing

struct TypedValueTests {
	@Test("Can find a typed value") func basic() throws {
		let source = """
		var a = 123
		a = "hi"
		"""
		let typer = try Typer(source: source)
		let results = typer.check()
		let scope = typer.context.currentScope

		let typedValue = scope.lookup(identifier: "a")!
		#expect(typedValue.type == .int)
		#expect(typedValue.definition.position == 0)

		let error = results.errors.first!
		#expect(error.message.contains("String not assignable"))
	}
}
