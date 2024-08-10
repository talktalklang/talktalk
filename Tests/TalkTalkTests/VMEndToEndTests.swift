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
import Testing

@MainActor
struct VMEndToEndTests {
	func compile(_ strings: String...) throws -> Module {
		try compile(strings)
	}

	func compile(_ strings: [String]) throws -> Module {
		let analysisModule = try ModuleAnalyzer(name: "E2E", files: strings.map { .tmp($0) }, moduleEnvironment: [:]).analyze()
		let compiler = ModuleCompiler(name: "E2E", analysisModule: analysisModule)
		return try compiler.compile(mode: .executable)
	}

	func compile(
		name: String,
		_ files: [ParsedSourceFile],
		analysisEnvironment: [String: AnalysisModule] = [:],
		moduleEnvironment: [String: Module] = [:]
	) throws -> (Module, AnalysisModule) {
		let analysis = moduleEnvironment.reduce(into: [:]) { res, tup in res[tup.key] = analysisEnvironment[tup.key] }
		let analyzed = try ModuleAnalyzer(name: name, files: files, moduleEnvironment: analysis).analyze()

		let module = try ModuleCompiler(name: name, analysisModule: analyzed, moduleEnvironment: moduleEnvironment).compile(mode: .executable)
		return (module, analyzed)
	}

	func run(_ strings: String..., verbose: Bool = false) throws -> TalkTalkBytecode.Value {
		let module = try compile(strings)
		return VirtualMachine.run(module: module, verbose: verbose).get()
	}

	func runAsync(_ strings: String...) throws {
		let module = try compile(strings)
		_ = VirtualMachine.run(module: module)
	}

	@Test("Adds") func adds() throws {
		#expect(try run("1 + 2") == .int(3))
	}

	@Test("Subtracts") func subtracts() throws {
		#expect(try run("2 - 1") == .int(1))
	}

	@Test("Comparison") func comparison() throws {
		#expect(try run("1 == 2") == .bool(false))
		#expect(try run("2 == 2") == .bool(true))

		#expect(try run("1 != 2") == .bool(true))
		#expect(try run("2 != 2") == .bool(false))

		#expect(try run("1 < 2") == .bool(true))
		#expect(try run("2 < 1") == .bool(false))

		#expect(try run("1 > 2") == .bool(false))
		#expect(try run("2 > 1") == .bool(true))

		#expect(try run("1 <= 2") == .bool(true))
		#expect(try run("2 <= 1") == .bool(false))
		#expect(try run("2 <= 2") == .bool(true))

		#expect(try run("1 >= 2") == .bool(false))
		#expect(try run("2 >= 1") == .bool(true))
		#expect(try run("2 >= 2") == .bool(true))
	}

	@Test("Negate") func negate() throws {
		#expect(try run("-123") == .int(-123))
		#expect(try run("--123") == .int(123))
	}

	@Test("Not") func not() throws {
		#expect(try run("!true") == .bool(false))
		#expect(try run("!false") == .bool(true))
	}

	@Test("Strings") func strings() throws {
		#expect(try run(#""hello world""#) == .data(0))
	}

	@Test("If expr") func ifExpr() throws {
		#expect(try run("""
		if false {
			123
		} else {
			456
		}
		""") == .int(456))
	}

	@Test("Var expr") func varExpr() throws {
		#expect(try run("""
		a = 10
		b = 20
		a = a + b
		a
		""") == .int(30))
	}

	@Test("Basic func/call expr") func funcExpr() throws {
		#expect(try run("""
		i = func() {
			123
		}()

		i + 1
		""") == .int(124))
	}

	@Test("Func arguments") func funcArgs() throws {
		#expect(try run("""
		func(i) {
			i + 20
		}(10)
		""") == .int(30))
	}

	@Test("Get var from enlosing scope") func enclosing() throws {
		#expect(try run("""
		a10 = 10
		b20 = 20
		func() {
			c30 = 30
			a10 + b20 + c30
		}()
		""") == .int(60))
	}

	@Test("Modify var from enclosing scope") func modifyEnclosing() throws {
		#expect(try run("""
		a = 10
		func() {
			a = 20
		}()
		a
		""") == .int(20))
	}

	@Test("Works with counter") func counter() throws {
		#expect(try run("""
		func makeCounter() {
			count = 0
			func increment() {
				count = count + 1
				count
			}
			increment
		}

		mycounter = makeCounter()
		mycounter()
		mycounter()
		""") == .int(2))
	}

	@Test("Doesn't leak out of closures") func closureLeak() throws {
		#expect(throws: CompilerError.self) {
			try compile("""
			func() {
			 a = 123
			}

			a
			""")
		}
	}

	@Test("Can run functions across files") func crossFile() throws {
		let out = try OutputCapture.run {
			try runAsync(
				"print(fizz())",
				"func foo() { bar() }",
				"func bar() { 123 }",
				"func fizz() { foo() }"
			)
		}

		#expect(out.stdout == ".int(123)\n")
	}

	@Test("Can use values across files") func crossFileValues() throws {
		let out = try OutputCapture.run {
			try runAsync(
				"print(fizz)",
				"print(fizz)",
				"fizz = 123"
			)
		}

		#expect(out.stdout == ".int(123)\n.int(123)\n")
	}

	@Test("Can run functions across modules") func crossModule() throws {
		let (moduleA, analysisA) = try compile(name: "A", [.tmp("func foo() { 123 }")], analysisEnvironment: [:], moduleEnvironment: [:])
		let (moduleB, _) = try compile(
			name: "B",
			[
				.tmp(
					"""
					import A

					func bar() {
						foo()
					}

					bar()
					"""
				)
			],
			analysisEnvironment: ["A": analysisA],
			moduleEnvironment: ["A": moduleA]
		)

		let result = VirtualMachine.run(module: moduleB).get()

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

					person = Person(age: 123)
					person.age
					"""
				)
			]
		)

		#expect(VirtualMachine.run(module: module).get() == .int(123))
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

					person = Person(age: 123)
					method = person.getAge
					method()
					"""
				)
			]
		)

		#expect(VirtualMachine.run(module: module).get() == .int(123))
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
					"""
				)
			]
		)

		let (moduleB, _) = try compile(
			name: "B",
			[
				.tmp("""
				import A
				
				person = Person(age: 123)
				person.age
				""")
			],
			analysisEnvironment: ["A": analysisA],
			moduleEnvironment: ["A": moduleA]
		)

		#expect(VirtualMachine.run(module: moduleB).get() == .int(123))
	}
}
