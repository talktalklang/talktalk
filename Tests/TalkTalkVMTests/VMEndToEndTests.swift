//
//  VMEndToEndTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Foundation
import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkSyntax
import TalkTalkVM
import TalkTalkCore
import Testing

struct VMEndToEndTests: VMTest {
	func runAsync(_ strings: String...) throws {
		let module = try compile(strings)
		_ = try VirtualMachine.run(module: module)
	}

	@Test("Adds") func adds() throws {
		#expect(try returning("1 + 2") == .int(3))
	}

	@Test("Subtracts") func subtracts() throws {
		#expect(try returning("2 - 1") == .int(1))
	}

	@Test("Comparison") func comparison() throws {
		#expect(try returning("1 == 2") == .bool(false))
		#expect(try returning("2 == 2") == .bool(true))

		#expect(try returning("1 != 2") == .bool(true))
		#expect(try returning("2 != 2") == .bool(false))

		#expect(try returning("1 < 2") == .bool(true))
		#expect(try returning("2 < 1") == .bool(false))

		#expect(try returning("1 > 2") == .bool(false))
		#expect(try returning("2 > 1") == .bool(true))

		#expect(try returning("1 <= 2") == .bool(true))
		#expect(try returning("2 <= 1") == .bool(false))
		#expect(try returning("2 <= 2") == .bool(true))

		#expect(try returning("1 >= 2") == .bool(false))
		#expect(try returning("2 >= 1") == .bool(true))
		#expect(try returning("2 >= 2") == .bool(true))
	}

	@Test("Negate") func negate() throws {
		#expect(try returning("-123") == .int(-123))
		#expect(try returning("--123") == .int(123))
	}

	@Test("Not") func not() throws {
		#expect(try returning("!true") == .bool(false))
		#expect(try returning("!false") == .bool(true))
	}

	@Test("Strings") func strings() throws {
		#expect(try returning(#""hello world""#) == .string("hello world"))
	}

	@Test("is check", .disabled()) func isCheck() throws {
		let result = try run(
			"""
			struct Person {}
			let person = Person()
			return person is Person
			"""
		)

		#expect(result == .bool(true))
	}

	@Test("If expr") func ifExpr() throws {
		let result = try run(
			"""
			return if false {
				123
			} else {
				456
			}
			"""
		)

		#expect(result == .int(456))
	}

	@Test("Var expr") func varExpr() throws {
		#expect(
			try run(
				"""
				var a = 10
				let b = 20
				a = a + b
				return a
				"""
			) == .int(30)
		)
	}

	@Test("Basic func/call expr") func funcExpr() throws {
		let source = """
		let i = func() {
			123
		}()

		return i + 1
		"""
		#expect(
			try run(source) == .int(124))
	}

	@Test("Func arguments") func funcArgs() throws {
		#expect(
			try run(
			"""
			func(i) {
				i + 20
			}(10)
			""") == .int(30))
	}

	@Test("Get var from enlosing scope") func enclosing() throws {
		let source = """
		let	a10 = 10
		let b20 = 20
		return func() {
			var c30 = 30
			return a10 + b20 + c30
		}()
		"""
		let result = try run(source)
		#expect(result == .int(60))
	}

	@Test("Modify var from enclosing scope") func modifyEnclosing() throws {
		let result = try run(
			"""
			var a = 10

			func() {
				a = 20
			}()

			return a
			"""
		)
		#expect(result == .int(20))
	}

	@Test("Shadow var from enclosing scope") func shadowEnclosing() throws {
		let result = try run(
			"""
			var a = 10
			var b = func() {
				var a = 20
				return a
			}()
			return a + b
			""")
		#expect(result == .int(30))
	}

	@Test("Works with counter") func counter() throws {
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

		let module = try compile(source)
		let result = try VirtualMachine.run(module: module).get()
		#expect(result == .int(2))
	}

	@Test("Runs factorial") func factorials() throws {
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
		let result = try run(source)

		#expect(result == .int(6))
	}

	@Test("Runs fib") func fib() throws {
		let source = """
			func fib(n) {
				if (n <= 1) {
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

		let result = try run(source)

		#expect(result == .int(34))
	}

	@Test("Doesn't leak out of closures") func closureLeak() throws {
		#expect(throws: CompilerError.self) {
			try compile(
				"""
				func() {
				 a = 123
				}

				return a
				""")
		}
	}

	@Test("Can run functions across files") func runsFunctionsAcrossFiles() throws {
		let result = try run(
				"func main() { fizz() }",
				"func foo() { bar() }",
				"func bar() { 123 }",
				"func fizz() { foo() }")

		#expect(result == .int(123))
	}

	@Test("Can use values across files") func crossFileValues() throws {
		let result = try run(
			"func main() { return fizz }",
			"let fizz = 123"
		)

		#expect(result == .int(123))
	}

	@Test("Can run functions across modules") func AcrossModule() throws {
		let (moduleA, analysisA) = try compile(
			name: "A", [.tmp("func foo() { 123 }", "1.tlk")], analysisEnvironment: [:], moduleEnvironment: [:]
		)
		let (moduleB, _) = try compile(
			name: "B",
			[
				.tmp(
					"""
					import A

					func bar() {
						foo()
					}

					return bar()
					""", "1.tlk"
				)
			],
			analysisEnvironment: ["A": analysisA],
			moduleEnvironment: ["A": moduleA]
		)

		let result = try VirtualMachine.run(module: moduleB).get()
		#expect(result == .int(123))
	}

	@Test("Struct properties") func structProperties() throws {
		let (module, _) = try compile(
			name: "A",
			[
				.tmp(
					"""
					struct Person {
						var age: int

						init(age) {
							self.age = age
						}
					}

					let person = Person(age: 123)
					return person.age
					""", "1.tlk"
				)
			]
		)

		#expect(try VirtualMachine.run(module: module).get() == .int(123))
	}

	@Test("Struct methods") func structMethods() throws {
		let (module, _) = try compile(
			name: "A",
			[
				.tmp(
					"""
					struct Person {
						var age: int

						init(age: int) {
							self.age = age
						}

						func getAge() {
							self.age
						}
					}

					let person = Person(age: 123)
					let method = person.getAge
					return method()
					""", "1.tlk"
				)
			]
		)

		#expect(try VirtualMachine.run(module: module).get() == .int(123))
	}

	@Test("Struct properties from other modules") func crossModuleStructProperties() throws {
		let (moduleA, analysisA) = try compile(
			name: "A",
			[
				.tmp(
					"""
					struct Person {
						var age: int

						init(age) {
							self.age = age
						}
					}
					""", "1.tlk"
				)
			]
		)

		let (moduleB, _) = try compile(
			name: "B",
			[
				.tmp(
					"""
					import A

					func() {
						let person = Person(age: 123)
						return person.age
					}()
					""", "1.tlk")
			],
			analysisEnvironment: ["A": analysisA],
			moduleEnvironment: ["A": moduleA]
		)

		#expect(try VirtualMachine.run(module: moduleB).get() == .int(123))
	}

	@Test("Struct synthesized init") func structSynthesizedInit() throws {
		let (module, _) = try compile(
			name: "A",
			[
				.tmp(
					"""
					struct Person {
						var age: int
					}

					let person = Person(age: 123)
					return person.age
					""", "1.tlk"
				)
			]
		)

		#expect(try VirtualMachine.run(module: module).get() == .int(123))
	}

	@Test("Struct init with no args") func structInitNoArgs() throws {
		let (module, _) = try compile(
			name: "A",
			[
				.tmp(
					"""
					struct Person {
						var age: int

						init() {
							self.age = 123
						}
					}

					let person = Person()
					return person.age
					""", "1.tlk"
				)
			]
		)

		#expect(try VirtualMachine.run(module: module).get() == .int(123))
	}

	@Test("While loops") func whileLoops() throws {
		let result = try run(
			"""
				var i = 0
				var j = 0

				while i < 5 {
					i = i + 1
					j = j + 1
				}

				return j
			"""
		)

		#expect(
			result == .int(5)
		)
	}

	@Test("Pass by value") func byValue() throws {
		let result = try run(
			"""
			func increments(v) {
				var t = v
				t = v + 1
			}


			var i = 3
			increments(i)
			return i
			"""
		)

		#expect(result == .int(3))
	}

	@Test("This was crashing") func crashing() throws {
		_ = try run(
			"""
			let a = [1,2,3]
			var i = 0

			while i < a.count {
				print(a[i])
				i += 1
			}
			"""
		)
	}

	@Test("+=") func plusEquals() throws {
		let result = try run(
			"""
			var a = 10
			a += 20
			return a
			"""
		)

		#expect(result == .int(30))
	}

	@Test("-=") func plusMinus() throws {
		let result = try run(
			"""
			var a = 20
			a -= 10
			return a
			"""
		)

		#expect(result == .int(10))
	}

	@Test("Random stuff (this was erroring)") func randomStuff() throws {
		let source = """
		func fib(n) {
			if (n <= 1) {
				return n
			}

			return fib(n - 2) + fib(n - 1)
		}

		var iterations = 3
		var i = 0

		while i <= iterations {
			print(fib(i))
			i = i + 1
		}

		func makeCounter() {
			var count = 0

			return func() {
				count = count + 1
				return count
			}
		}

		let counter = makeCounter()
		counter()
		print(counter())

		struct Person {
			init() {}

			func greet() {
				print("sup")
			}
		}

		var person = Person()
		person.greet()
		"""

		let output = TestOutput()
		_ = try run(source, output: output)

		#expect(output.stdout == """
		0
		1
		1
		2
		2
		sup

		""")
	}
}
