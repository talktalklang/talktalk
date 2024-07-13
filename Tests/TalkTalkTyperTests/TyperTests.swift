import TalkTalkSyntax
import TalkTalkTyper
import Testing

struct TyperTests {
	@Test("Assigns String") func takesString() throws {
		let typer = try Typer(
			source: """
			var foo = "bar"
			"""
		)

		let results = typer.check()
		#expect(results.typedef(at: 5)?.type.description == "String")
	}

	@Test("Assigns Int") func takesTypes() throws {
		let typer = try Typer(
			source: """
			var foo: Int = 42
			"""
		)

		let results = typer.check()
		#expect(results.typedef(at: 5)?.type.description == "Int")
	}

	@Test("Assigns bool") func assignsBool() throws {
		let results = try Typer(source: "var foo = true").check()

		#expect(results.typedef(at: 5)?.type.description == "Bool")
	}

	@Test("Errors on undeclared var") func undeclaredVar() throws {
		let results = try Typer(source: "foo = true").check()

		#expect(results.errors[0].syntax.position == 0)
		#expect(results.errors[0].syntax.length == 3)
		#expect(results.errors[0].message.contains("Unable to determine type of `foo`"))
	}

	@Test("Errors on bad var decl") func badVarDecl() throws {
		let typer = try Typer(
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
		let typer = try Typer(
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
		let typer = try Typer(
			source: """
			func foo() {
				return "bar"
			}
			"""
		)

		let results = typer.check()
		#expect(results.errors.isEmpty)

		let fntypedef = try #require(results.typedef(at: 7))
		#expect(fntypedef.type.description == "Function -> (String)")
	}

	@Test("Basic functions with type decl") func functionsWithType() throws {
		let typer = try Typer(
			source: """
			func foo(name) -> String {
				return name
			}
			"""
		)

		let results = typer.check()
		#expect(results.errors.isEmpty)

		let fntypedef = try #require(results.typedef(at: 7))
		#expect(fntypedef.type.description == "Function -> (String)")
	}

	@Test("Function tries to return wrong thing") func functionBadReturn() throws {
		let typer = try Typer(
			source: """
			func foo() -> String {
				return 123
			}
			"""
		)

		let results = typer.check()
		let fntypedef = try #require(results.typedef(at: 7))
		#expect(fntypedef.type.description == "Function -> (String)")

		let error = results.errors[0]
		#expect(error.syntax.position == 31)
		#expect(error.message.contains("Not assignable to String"))
	}

	@Test("Function has different return types") func functionBadReturn2() throws {
		let typer = try Typer(
			source: """
			func foo() {
				return 123
				return "sup"
			}
			"""
		)

		let results = typer.check()
		let fntypedef = try #require(results.typedef(at: 7))
		#expect(fntypedef.type.description == "Function -> (Int)")

		let error = results.errors[0]
		#expect(error.syntax.position == 33)
		#expect(error.message.contains("cannot return different types"))
	}

	@Test("Nested Function return types") func functionNested() throws {
		let source = """
		func makeCounter() {
			var i = 0
			func counter() {
				i = i + 1
				return i
			}

			return counter
		}

		var counter = makeCounter()
		"""
		let typer = try Typer(source: source)

		let results = typer.check()

		for error in results.errors {
			error.report(in: source)
		}

		let fntypedef = try #require(results.typedef(at: 7))
		#expect(fntypedef.type.description == "Function -> (Function -> (Int))")

		// Make sure we keep the right return type
		#expect(results.typedef(at: 104)?.type.description == "Function -> (Int)")
	}

	@Test("Classes") func classes() throws {
		let source = """
		class Person {}
		var person = Person()
		"""
		let typer = try Typer(source: source)

		let results = typer.check()
		let instanceDef = try #require(results.typedef(at: 21))
		#expect(instanceDef.type.description == "Person")
	}

	@Test("Class properties") func classProperties() throws {
		let source = """
		class Person {
			var age: Int?
		}
		var person = Person()
		person.age
		"""
		let typer = try Typer(source: source)

		let results = typer.check()
		for error in results.errors {
			error.report(in: source)
		}

		let propertyDef = try #require(results.typedef(at: 62))
		#expect(propertyDef.definition.cast(IdentifierSyntax.self).lexeme == "age")
	}
}
