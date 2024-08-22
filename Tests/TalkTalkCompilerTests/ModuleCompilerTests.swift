//
//  ModuleCompilerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkSyntax
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
			""", "1.tlk"),
			.tmp("""
			func bar() {
				123
			}
			""", "2.tlk"),
		]

		let (module, _) = try compile(name: "CompilerTests", files)
		#expect(module.name == "CompilerTests")

		#expect(module.chunks.map(\.name).sorted() == ["1.tlk", "2.tlk", "fizz", "foo", "bar", "main"].sorted())

		// We want each global function to have its own chunk in the module
		#expect(module.chunks.count == 6)
	}

	@Test("Can compile module global values") @MainActor func globalValues() throws {
		let files: [ParsedSourceFile] = [
			.tmp("""
			let fizz = 123
			""", "1.tlk"),
			.tmp("""
			func bar() {
				fizz
			}
			""", "2.tlk"),
		]

		let (module, _) = try compile(name: "CompilerTests", files)
		#expect(module.name == "CompilerTests")

		#expect(module.chunks.map(\.name).sorted() == ["1.tlk", "2.tlk", "bar", "main"].sorted())
		#expect(module.chunks.count == 4)
	}

	@Test("Can import module functions") @MainActor func importing() throws {
		let (moduleA, analysisA) = try compile(
			name: "A",
			[
				.tmp("func foo() { 123 }", "1.tlk"),
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
					""", "1.tlk"
				),
			],
			analysisEnvironment: ["A": analysisA],
			moduleEnvironment: ["A": moduleA]
		)

		#expect(moduleB.chunks.count == 4)
		#expect(moduleB.chunks.map(\.name).sorted() == ["1.tlk", "bar", "foo", "main"].sorted())
	}

	@Test("Can compile structs") @MainActor func structs() throws {
		// We test this in here instead of ChunkCompilerTests because struct defs on their own emit no code in chunk
		let (module, _) = try compile(name: "A", [
			.tmp("""
			struct Person {
				var age: int

				init(age: int) {
					self.age = age
				}
			}

			let person = Person(age: 123)
			""", "struct.tlk"),
		])

		let structDef = module.structs[0]
		#expect(structDef.name == "Person")
		#expect(structDef.propertyCount == 1)
		#expect(structDef.methods.count == 1)

		let initChunk = module.chunks[0]

		#expect(initChunk.disassemble(in: module) == Instructions(
			.op(.getLocal, line: 4, .local(slot: 1, name: "age")),
			.op(.getLocal, line: 4, .local(slot: 0, name: "__reserved__")),
			.op(.setProperty, line: 4, .property(slot: 0)),
			.op(.pop, line: 4, .simple),
			.op(.getLocal, line: 6, .local(slot: 0, name: "__reserved__")),
			.op(.return, line: 6, .simple)
		))
	}

	@Test("Can compile struct init with no args") @MainActor func structInitNoArgs() throws {
		// We test this in here instead of ChunkCompilerTests because struct defs on their own emit no code in chunk
		let (module, _) = try compile(name: "A", [
			.tmp("""
			struct Person {
				var age: int

				init() {
					self.age = 123
				}
			}

			let person = Person()
			""", "1.tlk"),
		])

		// Get the actual code, not the synthesized main
		let mainChunk = try #require(module.chunks[1])
		#expect(mainChunk.disassemble(in: module) == Instructions(
			.op(.getStruct, line: 8, .struct(slot: 0)),
			.op(.call, line: 8),
			.op(.setModuleValue, line: 8, .global(slot: 2)),
			.op(.return, line: 0)
		))

		let structDef = module.structs[0]
		#expect(structDef.name == "Person")
		#expect(structDef.propertyCount == 1)
		#expect(structDef.methods.count == 1)

		let initChunk = module.chunks[0]
		#expect(initChunk.disassemble() == Instructions(
			.op(.constant, line: 4, .constant(.int(123))),
			.op(.getLocal, line: 4, .local(slot: 0, name: "__reserved__")),
			.op(.setProperty, line: 4, .property(slot: 0)),
			.op(.pop, line: 4, .simple),
			.op(.getLocal, line: 6, .local(slot: 0, name: "__reserved__")),
			.op(.return, line: 6, .simple)
		))
	}
}
