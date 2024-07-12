import Testing
import TalkTalkTyper

struct TyperTests {
	@Test("Takes String") func takesString() {
		let typer = Typer(
			source: """
			var foo = "bar"
			"""
		)

		let results = typer.check()
		#expect(results.typedef(at: 5)?.name == "String")
	}

	@Test("Takes types") func takesTypes() {
		let typer = Typer(
			source: """
			var foo: Int = 42
			"""
		)

		let results = typer.check()
		#expect(results.typedef(at: 5)?.name == "Int")
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
	}
}
