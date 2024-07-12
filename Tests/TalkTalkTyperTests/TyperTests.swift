import TalkTalkSyntax
import TalkTalkTyper
import Testing

struct TyperTests {
	@Test("Assigns String") func takesString() {
		let typer = Typer(
			source: """
			var foo = "bar"
			"""
		)

		let results = typer.check()
		#expect(results.typedef(at: 5)?.name == "String")
	}

	@Test("Assigns Int") func takesTypes() {
		let typer = Typer(
			source: """
			var foo: Int = 42
			"""
		)

		let results = typer.check()
		#expect(results.typedef(at: 5)?.name == "Int")
	}

	@Test("Assigns bool") func assignsBool() {
		let results = Typer(source: "var foo = true").check()

		#expect(results.typedef(at: 5)?.name == "Bool")
	}

	@Test("Errors on undeclared var") func undeclaredVar() {
		let results = Typer(source: "foo = true").check()

		#expect(results.errors[0].syntax.position == 0)
		#expect(results.errors[0].syntax.length == 3)
		#expect(results.errors[0].message.contains("Unknown variable: foo"))
	}

	@Test("Errors on bad var decl") func badVarDecl() throws {
		let typer = Typer(
			source: """
			var foo: Int = "bar"
			"""
		)

		let results = typer.check()
		let error = try #require(results.errors.first)

		#expect(error.syntax.position == 4)
		#expect(error.message.contains("not assignable"))
	}

	@Test("Error on bad assignment") func badAssignment() throws {
		let typer = Typer(
			source: """
			var foo = "bar"
			foo = 123
			"""
		)

		let results = typer.check()
		let error = try #require(results.errors.first)

		#expect(error.syntax.position == 22)
		#expect(error.message.contains("not assignable to `foo`, expected String"))
	}

	@Test("Basic functions") func functions() throws {
		let typer = Typer(
			source: """
			func foo() {
				return "bar"
			}
			"""
		)

		let results = typer.check()
		#expect(results.errors.isEmpty)

		let fntypedef = try #require(results.typedef(at: 7))
		#expect(fntypedef.name == "Function<String>")
	}

	@Test("Basic functions with type decl") func functionsWithType() throws {
		let typer = Typer(
			source: """
			func foo(name) -> String {
				return name
			}
			"""
		)

		let results = typer.check()
		#expect(results.errors.isEmpty)

		let fntypedef = try #require(results.typedef(at: 7))
		#expect(fntypedef.name == "Function<String>")
	}

	@Test("Function tries to return wrong thing") func functionBadReturn() throws {
		let typer = Typer(
			source: """
			func foo() -> String {
				return 123
			}
			"""
		)

		let results = typer.check()
		let fntypedef = try #require(results.typedef(at: 7))
		#expect(fntypedef.name == "Function<String>")

		let error = results.errors[0]
		#expect(error.syntax.position == 31)
		#expect(error.message.contains("Not assignable to String"))
	}

	@Test("Function has different return types") func functionBadReturn2() throws {
		let typer = Typer(
			source: """
			func foo() {
				return 123
				return "sup"
			}
			"""
		)

		let results = typer.check()
		let fntypedef = try #require(results.typedef(at: 7))
		#expect(fntypedef.name == "Function<Int>")

		let error = results.errors[0]
		#expect(error.syntax.position == 33)
		#expect(error.message.contains("cannot return different types"))
	}
}
