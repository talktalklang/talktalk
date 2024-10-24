//
//  InterpreterTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/24/24.
//

import Interpreter
import TalkTalkCore
import Testing
import TypeChecker

struct InterpreterTests {
	func run(_ string: String, imports: [Context] = [], verbose: Bool = false) async throws -> ReturnValue {
		let parsed = try Parser.parse(SourceFile(path: "test.talk", text: string))
		let context = try Typer(module: "InterpreterTests", imports: imports, verbose: verbose).solve(parsed)

		return try await Interpreter(typeContext: context).run(parsed)
	}

	@Test("Can interpret literals") func int() async throws {
		#expect(try await run("1") == .value(.int(1)))
		#expect(try await run(#""hello""#) == .value(.string("hello")))
		#expect(try await run("true") == .value(.bool(true)))
		#expect(try await run("nil") == .value(.nil))
	}

	@Test("Can add literals") func add() async throws {
		#expect(try await run("1 + 2") == .value(.int(3)))
		#expect(try await run(#""hello " + "world""#) == .value(.string("hello world")))
	}

	@Test("Can subtract literals") func subtract() async throws {
		#expect(try await run("1 - 2") == .value(.int(-1)))
	}

	@Test("Modulo") func mod() async throws {
		#expect(try await run("5 % 2") == .value(.int(1)))
		#expect(try await run("4 % 2") == .value(.int(0)))
	}

	@Test("If expr") func ifExpr() async throws {
		let result = try await run(
			"""
			return if false {
				123
			} else {
				456
			}
			"""
		)

		#expect(result == .returning(.int(456)))
	}

	@Test("Var expr") func varExpr() async throws {
		let result = try await run(
		"""
			var a = 10
			let b = 20
			a = a + b
			return a
			"""
		)
		#expect(
			result == .returning(.int(30))
		)
	}

	@Test("Basic func/call expr") func funcExpr() async throws {
		let source = """
		let i = func() {
			123
		}()

		return i + 1
		"""

		let result = try await run(source)
		#expect(result == .returning(.int(124)))
	}

	@Test("Func arguments") func funcArgs() async throws {
		#expect(
			try await run(
				"""
				func(i) {
					i + 20
				}(10)
		""") == .value(.int(30)))
	}

	@Test("Get var from enlosing scope") func enclosing() async throws {
		let source = """
		let	a10 = 10
		let b20 = 20
		return func() {
			var c30 = 30
			return a10 + b20 + c30
		}()
		"""
		let result = try await run(source)
		#expect(result == .returning(.int(60)))
	}

	@Test("Modify var from enclosing scope") func modifyEnclosing() async throws {
		let result = try await run(
			"""
			var a = 10

			func() {
				a = 20
			}()

			return a
			"""
		)
		#expect(result == .returning(.int(20)))
	}

	@Test("Shadow var from enclosing scope") func shadowEnclosing() async throws {
		let result = try await run(
			"""
			var a = 10
			var b = func() {
				var a = 20
				return a
			}()
			return a + b
			""")

		#expect(result == .returning(.int(30)))
	}

	@Test("Works with counter") func counter() async throws {
		let source = """
		func makeCounter() {
			var count = 0
			func increment() {
				count = count + 1
				return count
			}
			return increment
		}

		var mycounter = makeCounter()
		mycounter()
		return mycounter()
		"""

		let result = try await run(source)
		#expect(result == .returning(.int(2)))
	}

	@Test("Runs factorial") func factorials() async throws {
		let source = """
		func fact(n) {
			if n <= 1 {
				return 1
			} else {
				return n * fact(n - 1)
			}
		}
		return fact(3)
		"""

		let result = try await run(source)

		#expect(result == .returning(.int(6)))
	}

	@Test("Runs fib") func fib() async throws {
		let source = """
			func fib(n) {
				if n <= 1 {
					return n
				}
				return fib(n - 2) + fib(n - 1)
			}

			var i = 0
			var n = 0
			while i < 10 {
				n = fib(i)
				i = i + 1
			}

			return n
		"""

		let result = try await run(source)
		#expect(result == .returning(.int(34)))
	}

	@Test("Doesn't leak out of closures") func closureLeak() async throws {
		await #expect(throws: RuntimeError.self) {
			try await run(
				"""
				func() {
				 a = 123
				}

				return a
				""")
		}
	}
}
