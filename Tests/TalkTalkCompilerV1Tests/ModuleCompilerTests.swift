//
//  ModuleCompilerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompilerV1
import TalkTalkCore
import Testing

extension [Instruction]: @retroactive CustomTestStringConvertible {
	public var testDescription: String {
		"\n" + map(\.description).joined(separator: "\n")
	}
}

@MainActor
struct ModuleCompilerTests: CompilerTest {
	@Test("Can compile module functions") @MainActor func basic() throws {
		let files: [ParsedSourceFile] = [
			.tmp("""
			func fizz() {}

			func foo() {
				bar()
			}
			""", "1.talk"),
			.tmp("""
			func bar() {
				123
			}
			""", "2.talk"),
		]

		let (module, _) = try compile(name: "CompilerTests", files)
		#expect(module.name == "CompilerTests")

		for name in ["1.talk", "2.talk", "fizz", "foo", "bar", "main"] {
			#expect(module.chunks.values.map(\.name).contains(name))
		}
	}

	@Test("Handles global functions") func globalFunc() throws {
		let (module, _) = try compile(name: "GlobalFuncs", [
			.tmp("""
			func foo() {
				123
			}

			let a = foo()
			""", "global.talk"),
		])

		let chunk = module.chunks.values.first(where: { $0.name == "global.talk" })!

		try #expect(chunk.disassemble(in: module) == Instructions(
			.op(.defClosure, line: 0, .closure(name: "foo", arity: 0, depth: 0)),
			.op(.getModuleFunction, line: 4, .moduleFunction(.function("GlobalFuncs", "foo", []))),
			.op(.call, line: 4),
			.op(.setModuleValue, line: 4, .global(.value("GlobalFuncs", "a"))),
			.op(.returnVoid, line: 0)
		))
	}

	@Test("Can compile module global values") @MainActor func globalValues() throws {
		let files: [ParsedSourceFile] = [
			.tmp("""
			let fizz = 123
			""", "1.talk"),
			.tmp("""
			func bar() {
				fizz
			}
			""", "2.talk"),
		]

		let (module, _) = try compile(name: "CompilerTests", files)
		#expect(module.name == "CompilerTests")

		#expect(module.chunks.values.map(\.name).sorted().contains(["1.talk", "2.talk", "bar", "main"]))
	}

	@Test("Can import module functions") @MainActor func importing() throws {
		let (moduleA, analysisA) = try compile(
			name: "A",
			[
				.tmp("func foo() { 123 }", "1.talk"),
			]
		)
		let (moduleB, _) = try compile(
			name: "B",
			[
				.tmp("""
				import A

				func bar() {
					foo()
				}
				""", "1.talk"),
			],
			analysisEnvironment: ["A": analysisA],
			moduleEnvironment: ["A": moduleA]
		)

		#expect(moduleB.chunks.values.map(\.name).sorted().contains(["1.talk", "bar", "foo", "main"].sorted()))
	}

	@Test("Can compile structs") func structs() throws {
		let (module, _) = try compile(name: "A", [
			.tmp("""
			struct Person {
				var age: int

				init(age: int) {
					self.age = age
				}
			}

			let person = Person(age: 123)
			""", "struct.talk"),
		])

		let structDef = module.structs.values.first(where: { $0.name == "Person" })!
		#expect(structDef.name == "Person")
		#expect(structDef.propertyCount == 1)

		let initChunk = module.chunks[structDef.initializer!]!

		#expect(try initChunk.disassemble(in: module) == Instructions(
			.op(.getLocal, line: 4, .local(.value("A", "age"))),
			.op(.getLocal, line: 4, .local(.value("A", "self"))),
			.op(.setProperty, line: 4, .property(.property("A", "Person", "age"))),
			.op(.getLocal, line: 5, .local(.value("A", "self"))),
			.op(.returnValue, line: 5, .simple)
		))
	}

	@Test("Can compile struct init with no args") @MainActor func compileStructInitNoArgs() throws {
		let (module, _) = try compile(name: "A", [
			.tmp("""
			struct Person {
				var age: int

				init() {
					self.age = 123
				}
			}

			let person = Person()
			""", "1.talk"),
		])

		// Get the actual code, not the synthesized main
		let mainChunk = module.chunks[.function("A", "1.talk", [])]!
		try #expect(mainChunk.disassemble(in: module) == Instructions(
			.op(.getStruct, line: 8, .struct(.struct("A", "Person"))),
			.op(.call, line: 8),
			.op(.setModuleValue, line: 8, .global(.value("A", "person"))),
			.op(.returnVoid, line: 0)
		))

		let structDef = module.structs.values.first(where: { $0.name == "Person" })!
		#expect(structDef.name == "Person")
		#expect(structDef.propertyCount == 1)

		let initChunk = module.chunks[structDef.initializer!]!
		try #expect(initChunk.disassemble() == Instructions(
			.op(.constant, line: 4, .constant(.int(123))),
			.op(.getLocal, line: 4, .local(.value("A", "self"))),
			.op(.setProperty, line: 4, .property(.property("A", "Person", "age"))),
			.op(.getLocal, line: 5, .local(.value("A", "self"))),
			.op(.returnValue, line: 5, .simple)
		))
	}
}
