//
//  StructTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/23/24.
//

import Testing

struct StructTests: CompilerTest {
	@Test("Struct initializer") func structs() throws {
		let module = try compile("""
		struct Person {
			var age: int

			init(age: int) {
				self.age = age
			}
		}

		Person(age: 123)
		""")

		let main = module.chunks[.function(module.name, "0.talk", [])]!

		try #expect(main.disassemble(in: module) == Instructions(
			.op(.constant, line: 8, .constant(.int(123))),
			.op(.getStruct, line: 8, .struct(.struct("E2E", "Person"))),
			.op(.call, line: 8, .simple),
			.op(.pop, line: 8, .simple),
			.op(.returnVoid, line: 0, .simple)
		))
	}

	@Test("Struct init with no args") func structInitNoArgs() throws {
		let module = try compile("""
		struct Person {
			var age: int

			init() {
				self.age = 123
			}
		}

		Person()
		""")

		let main = module.chunks[.function(module.name, "0.talk", [])]!

		try #expect(main.disassemble(in: module) == Instructions(
			.op(.getStruct, line: 8, .struct(.struct("E2E", "Person"))),
			.op(.call, line: 8, .simple),
			.op(.pop, line: 8, .simple),
			.op(.returnVoid, line: 0, .simple)
		))
	}

	@Test("Struct property getter") func structsProperties() throws {
		let module = try compile("""
		struct Person {
			var age: int

			init(age: int) { self.age = age }
		}

		Person(age: 123).age
		""")

		let main = module.chunks[.function(module.name, "0.talk", [])]!

		try #expect(main.disassemble(in: module) == Instructions(
			.op(.constant, line: 6, .constant(.int(123))),
			.op(.getStruct, line: 6, .struct(.struct("E2E", "Person"))),
			.op(.call, line: 6, .simple),
			.op(.getProperty, line: 6, .getProperty(.property("E2E", "Person", "age"), options: [])),
			.op(.pop, line: 6, .simple),
			.op(.returnVoid, line: 0, .simple)
		))
	}

	@Test("Struct methods") func structMethods() throws {
		let module = try compile("""
		struct Person {
			var age: int

			init(age: int) { self.age = age }

			func getAge() {
				self.age
			}
		}

		Person(age: 123).getAge()
		""")

		let main = module.chunks[.function(module.name, "0.talk", [])]!

		try #expect(main.disassemble(in: module) == Instructions(
			.op(.constant, line: 10, .constant(.int(123))),
			.op(.getStruct, line: 10, .struct(.struct("E2E", "Person"))),
			.op(.call, line: 10, .simple),
			.op(.invokeMethod, line: 10, .invokeMethod(.method("E2E", "Person", "getAge", []))),
			.op(.pop, line: 10, .simple),
			.op(.returnVoid, line: 0, .simple)
		))
	}

	@Test("Struct static let") func staticLet() throws {
		let module = try compile("""
		struct Person {
			static let age: int = 123
		}

		Person.age
		""")

		let main = module.chunks[.function(module.name, "0.talk", [])]!

		try #expect(main.disassemble(in: module) == Instructions(
			.op(.getStruct, line: 4, .struct(.struct("E2E", "Person"))),
			.op(.getProperty, line: 4, .getProperty(.property("E2E", "Person", "age"), options: [])),
			.op(.pop, line: 4, .simple),
			.op(.returnVoid, line: 0, .simple)
		))
	}

	@Test("Struct static var") func staticVar() throws {
		let module = try compile("""
		struct Person {
			static var age: int = 123
		}

		Person.age
		""")

		let main = module.chunks[.function(module.name, "0.talk", [])]!

		try #expect(main.disassemble(in: module) == Instructions(
			.op(.getStruct, line: 4, .struct(.struct("E2E", "Person"))),
			.op(.getProperty, line: 4, .getProperty(.property("E2E", "Person", "age"), options: [])),
			.op(.pop, line: 4, .simple),
			.op(.returnVoid, line: 0, .simple)
		))
	}

	@Test("Struct static method") func staticMethod() throws {
		let module = try compile("""
		struct Person {
			static func age() { 123 } 
		}

		Person.age()
		""")

		let main = module.chunks[.function(module.name, "0.talk", [])]!

		try #expect(main.disassemble(in: module) == Instructions(
			.op(.getStruct, line: 4, .struct(.struct("E2E", "Person"))),
			.op(.invokeMethod, line: 4, .invokeMethod(.method("E2E", "Person", "age", []))),
			.op(.pop, line: 4, .simple),
			.op(.returnVoid, line: 0, .simple)
		))
	}
}
