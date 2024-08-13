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

@MainActor
struct ModuleCompilerTests {
	func compile(
		name: String,
		_ files: [ParsedSourceFile],
		analysisEnvironment: [String: AnalysisModule] = [:],
		moduleEnvironment: [String: Module] = [:]
	) -> (Module, AnalysisModule) {
		let analysis = moduleEnvironment.reduce(into: [:]) { res, tup in res[tup.key] = analysisEnvironment[tup.key] }
		let analyzed = try! ModuleAnalyzer(name: name, files: files, moduleEnvironment: analysis).analyze()
		let module = try! ModuleCompiler(name: name, analysisModule: analyzed, moduleEnvironment: moduleEnvironment).compile(mode: .executable)
		return (module, analyzed)
	}

	@Test("Can compile module functions") @MainActor func basic() {
		let files: [ParsedSourceFile] = [
			.tmp("""
			func fizz() {}

			func foo() {
				bar()
			}
			"""),
			.tmp("""
			func bar() {
				123
			}
			""")
		]

		let (module, _) = compile(name: "CompilerTests", files)
		#expect(module.name == "CompilerTests")

		#expect(module.chunks.map(\.name).sorted() == ["fizz", "foo", "bar"].sorted())

		// We want each global function to have its own chunk in the module
		#expect(module.chunks.count == 3)
	}

	@Test("Can compile module global values") @MainActor func globalValues() throws {
		let files: [ParsedSourceFile] = [
			.tmp("""
			fizz = 123
			"""),
			.tmp("""
			func bar() {
				fizz
			}
			""")
		]

		let (module, _) = compile(name: "CompilerTests", files)
		#expect(module.name == "CompilerTests")

		#expect(module.chunks.map(\.name).sorted() == ["bar"].sorted())
		#expect(module.chunks.count == 1)

		let fizzSlot = try #require(module.symbols[.value("fizz")])
		#expect(module.valueInitializers[Byte(fizzSlot)] != nil)
	}

	@Test("Can import module functions") @MainActor func importing() {
		let (moduleA, analysisA) = compile(
			name: "A",
			[
				.tmp("func foo() { 123 }")
			]
		)
		let (moduleB, _) = compile(
			name: "B",
			[
				.tmp("""
					import A

					func bar() {
						foo()
					}
					"""
				)
			],
			analysisEnvironment: ["A": analysisA],
			moduleEnvironment: ["A": moduleA]
		)

		#expect(moduleB.chunks.count == 2)
		#expect(moduleB.chunks.map(\.name).sorted() == ["bar", "foo"].sorted())
	}

	@Test("Can compile structs") @MainActor func structs() throws {
		// We test this in here instead of ChunkCompilerTests because struct defs on their own emit no code in chunk
		let (module, _) = compile(name: "A", [
			.tmp("""
			struct Person {
				var age: int

				init(age: int) {
					self.age = age
				}
			}

			person = Person(age: 123)
			""")
		])

		let structDef = module.structs[0]
		#expect(structDef.name == "Person")
		#expect(structDef.propertyCount == 1)
		#expect(structDef.methods.count == 1)

		let initChunk = structDef.methods[0]

		#expect(initChunk.disassemble() == [
			Instruction(opcode: .getLocal, offset: 0, line: 4, metadata: .local(slot: 1, name: "age")),
			Instruction(opcode: .getLocal, offset: 2, line: 4, metadata: .local(slot: 0, name: "__reserved__")),
			Instruction(opcode: .setProperty, offset: 4, line: 4, metadata: .property(slot: 0)),
			Instruction(opcode: .pop, offset: 6, line: 4, metadata: .simple),
			Instruction(opcode: .return, offset: 7, line: 6, metadata: .simple)
		])
	}

	@Test("Can compile struct init with no args") @MainActor func structInitNoArgs() throws {
		// We test this in here instead of ChunkCompilerTests because struct defs on their own emit no code in chunk
		let (module, _) = compile(name: "A", [
			.tmp("""
			struct Person {
				var age: int

				init() {
					self.age = 123
				}
			}

			person = Person()
			""")
		])

		// Get the actual code, not the synthesized main
		let mainChunk = try #require(module.main?.getChunk(at: 0))

		#expect(mainChunk.disassemble() == [
			Instruction(opcode: .pop, offset: 0, line: 0, metadata: .simple),
			Instruction(opcode: .getStruct, offset: 1, line: 8, metadata: .struct(slot: 0)),
			Instruction(opcode: .call, offset: 3, line: 8, metadata: .simple),
			Instruction(opcode: .setModuleValue, offset: 4, line: 8, metadata: .global(slot: 0)),
			Instruction(opcode: .pop, offset: 6, line: 8, metadata: .simple),
			Instruction(opcode: .return, offset: 7, line: 0, metadata: .simple)
		])

		let structDef = module.structs[0]
		#expect(structDef.name == "Person")
		#expect(structDef.propertyCount == 1)
		#expect(structDef.methods.count == 1)

		let initChunk = structDef.methods[0]
		#expect(initChunk.disassemble() == [
			Instruction(opcode: .constant, offset: 0, line: 4, metadata: .constant(.int(123))),
			Instruction(opcode: .getLocal, offset: 2, line: 4, metadata: .local(slot: 0, name: "__reserved__")),
			Instruction(opcode: .setProperty, offset: 4, line: 4, metadata: .property(slot: 0)),
			Instruction(opcode: .pop, offset: 6, line: 4, metadata: .simple),
			Instruction(opcode: .return, offset: 6, line: 6, metadata: .simple)
		])
	}
}
