import TalkTalkSyntax
import TalkTalkTyper
import Testing

struct TyperTests {
	func typer(_ source: String) -> Typer {
		try! Typer(source: .init(path: "typer test", source: source))
	}

	@Test("Assigns String") func takesString() throws {
		let typer = typer("""
			var foo = "bar"
			"""
		)

		let results = typer.check()
		#expect(results.typedef(at: 5)!.type.description == "String")
	}

	@Test("Assigns Int") func takesTypes() throws {
		let typer = typer("""
			var foo: Int = 42
			"""
		)

		let results = typer.check()

		#expect(results.typedef(at: 5)?.type != nil)
	}

	@Test("Assigns bool") func assignsBool() throws {
		let results = typer("var foo = true").check()

		#expect(results.typedef(at: 5)?.type.description == "Bool")
	}

	@Test("Errors on undeclared var") func undeclaredVar() throws {
		let results = typer("foo = true").check()

		#expect(results.errors[0].syntax.position == 0)
		#expect(results.errors[0].syntax.length == 3)
		#expect(results.errors[0].message.contains("Unable to determine type of `foo`"))
	}

	@Test("Errors on bad var decl") func badVarDecl() throws {
		let typer = typer("""
			var foo: Int = "bar"
			"""
		)

		let results = typer.check()
		let error = try #require(results.errors.first)

		#expect(error.syntax.position == 4)
		#expect(error.message.contains("not assignable"))
	}

	@Test("Error on bad assignment") func badAssignment() throws {
		let typer = typer("""
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
		let typer = typer("""
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

	@Test("Basic functions with return type") func functionsRet() throws {
		let typer = typer("""
			func foo() {
				return 123
			}
			"""
		)

		let results = typer.check()
		#expect(results.errors.isEmpty)

		let fntypedef = try #require(results.typedef(at: 7))
		#expect(fntypedef.type.description == "Function -> (Int)")
	}

	@Test("Basic functions with type decl") func functionsWithType() throws {
		let typer = typer("""
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
		let typer = typer("""
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
		let typer = typer("""
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
		let typer = typer(source)

		let results = typer.check()

		for error in results.errors {
			error.report(in: typer.file)
		}

		let fntypedef = try #require(results.typedef(at: 7))
		#expect(fntypedef.type.description == "Function -> (Function -> (Int))")

		// Make sure we keep the right return type
		#expect(results.typedef(at: 104)?.type.description == "Function -> (Int)")
	}

	@Test("Function with conditional") func functionConditions() throws {
		let source = """
		func id() {
			if false {
				return 123
			} else {
				return 456
			}
		}
		"""
		let typer = typer(source)
		let results = typer.check()

		for error in results.errors {
			error.report(in: typer.file)
		}

		let fndef = try #require(results.typedef(at: 6))

		#expect(fndef.returnDef() == .int)
	}

	@Test("Function args") func functionArgs() throws {
		let source = """
		func id(n) -> Int {
			return n
		}
		"""
		let typer = typer(source)
		let results = typer.check()

		for error in results.errors {
			error.report(in: typer.file)
		}

		let ndef = try #require(results.typedef(at: 28))

		#expect(ndef.type == .int)
	}

	@Test("Function return with args") func functionReturnArgs() throws {
		let source = """
		func fib(n) {
			if (n <= 1) {
				return n
			}

			return fib(n - 2) + fib(n - 1)
		}
		"""
		let typer = typer(source)
		let results = typer.check()

		#expect(results.errors.isEmpty)

		let ndef = try #require(results.typedef(at: 6))
		#expect(ndef.type == .function(.int))

		let paramdef = try #require(results.typedef(at: 9))
		#expect(paramdef.type == .int)
	}

	@Test("Classes") func classes() throws {
		let source = """
		class Person {}
		var person = Person()
		"""
		let typer = typer(source)

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
		let typer = typer(source)

		let results = typer.check()
		for error in results.errors {
			error.report(in: typer.file)
		}

		let propertyDef = try #require(results.typedef(at: source.count - 1))
		#expect(propertyDef.definition.cast(PropertyDeclSyntax.self).name.lexeme == "age")
	}

	@Test("Class methods") func classMethods() throws {
		let source = """
		class Person {
			func age() {
				return 123
			}
		}
		var age = Person().age()
		"""
		let typer = typer(source)

		let results = typer.check()
		for error in results.errors {
			error.report(in: typer.file)
		}

		let propertyDef = try #require(results.typedef(at: 53))
		#expect(propertyDef.definition.cast(VarDeclSyntax.self).variable.lexeme == "age")
		#expect(propertyDef.type.description == "Int")
	}

	@Test("If expressions") func ifExpressions() throws {
		let source = """
		var name = if true {
			"Pat"
		} else {
			"Not Pat"
		}

		name = 123
		"""
		let typer = typer(source)

		let results = typer.check()
		let def = try #require(results.typedef(at: 6))
		#expect(def.definition.cast(VarDeclSyntax.self).variable.lexeme == "name")
		#expect(def.type.description == "String")
		#expect(results.errors.count == 1)

		let ifdef = try #require(results.typedef(at: 12))
		#expect(ifdef.definition.cast(IfExprSyntax.self).condition.description == "true")
		#expect(ifdef.type.description == "String")
	}

	@Test("If statements") func ifStatements() throws {
		let source = """
		func foo() {
			if true {
				return "Pat"
			} else {
				return "Not Pat"
			}
		}
		"""
		let typer = typer(source)

		let results = typer.check()
		let def = try #require(results.typedef(at: 32))
		#expect(def.type.description == "String")
		#expect(results.errors.count == 0)
	}

	@Test("lets cant be re-assigned") func letReassignment() throws {
		let source = """
		let foo = 123
		foo = 345
		"""
		let typer = typer(source)

		let results = typer.check()
		#expect(results.errors.count == 1)
		#expect(results.errors[0].message.contains("Cannot reassign let variable: `foo`"))
	}
}
