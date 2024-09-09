//
//  ChunkCompilerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

@testable import TalkTalkAnalysis
import TalkTalkBytecode
@testable import TalkTalkCompiler
import TalkTalkSyntax
import Testing
import TypeChecker

// Helper for building instruction expectations.
// Moving stuff around always required updating a bunch of offsets
// even for unrelated stuff. This helper automatically syncs offsets
// and just requires opcode/line/metadata which tends to be more
// interesting. It uses Metadata's length field to determine how much
// to move the offset.
struct Instructions: CustomStringConvertible, CustomTestStringConvertible {
	struct Expectation {
		let opcode: Opcode
		let line: UInt32
		let metadata: any InstructionMetadata

		static func op(_ opcode: Opcode, line: UInt32, _ metadata: any InstructionMetadata = .simple) -> Expectation {
			Expectation(opcode: opcode, line: line, metadata: metadata)
		}
	}

	static func == (lhs: [Instruction], rhs: Instructions) -> Bool {
		lhs == rhs.instructions
	}

	let expectations: [Expectation]

	init(_ expectations: Expectation...) {
		self.expectations = expectations
	}

	init(_ expectations: [Expectation]) {
		self.expectations = expectations
	}

	var description: String {
		instructions.map(\.description).joined(separator: "\n")
	}

	var testDescription: String {
		"\n" + description
	}

	var instructions: [Instruction] {
		var result: [Instruction] = []
		var i = 0

		for expectation in expectations {
			let instruction = Instruction(
				path: "<expectation>",
				opcode: expectation.opcode,
				offset: i,
				line: expectation.line,
				metadata: expectation.metadata
			)

			result.append(instruction)
			i += expectation.metadata.length
		}

		return result
	}
}

@MainActor
class CompilerTests: CompilerTest {
	var module: CompilingModule!

	@discardableResult func compile(_ string: String) throws -> Chunk {
		let parsed = try Parser.parse(.init(path: "chunkcompilertests.tlk", text: string))
		let inferencer = try Inferencer(imports: []).infer(parsed)
		let analyzed = try! SourceFileAnalyzer.analyze(
			parsed,
			in: Environment(
				inferenceContext: inferencer,
				isModuleScope: true,
				symbolGenerator: .init(moduleName: "CompilerTests", parent: nil)
			)
		)

		let analysisModule = try ModuleAnalyzer(
			name: "CompilerTests",
			files: [.tmp(string, "1.tlk")],
			moduleEnvironment: [:],
			importedModules: []
		).analyze()

		self.module = CompilingModule(name: "CompilerTests", analysisModule: analysisModule, moduleEnvironment: [:])
		return try module.compile(file: AnalyzedSourceFile(path: "1.tlk", syntax: analyzed))
	}

	func disassemble(_ chunk: Chunk) -> [Instruction] {
		try! chunk.disassemble(in: module.finalize(mode: .executable))
	}

	@Test("Empty program") func empty() throws {
		let chunk = try compile("")
		try #expect(chunk.disassemble()[0].opcode == .return)
	}

	@Test("Int literal") func intLiteral() throws {
		let chunk = try compile("123")

		let instructions = Instructions([
			.init(opcode: .constant, line: 0, metadata: .constant(.int(123))),
			.init(opcode: .pop, line: 0, metadata: .simple),
			.init(opcode: .return, line: 0, metadata: .simple),
		])

		let expected = [
			Instruction(path: chunk.path, opcode: .constant, offset: 0, line: 0, metadata: ConstantMetadata(value: .int(123))),
			Instruction(path: chunk.path, opcode: .pop, offset: 2, line: 0, metadata: .simple),
			Instruction(path: chunk.path, opcode: .return, offset: 3, line: 0, metadata: .simple),
		]

		#expect(instructions.instructions == expected)
		try #expect(chunk.disassemble() == instructions)
	}

	@Test("Binary int op") func binaryIntOp() throws {
		let chunk = try compile("10 + 20")

		let instructions = [
			Instruction(path: chunk.path, opcode: .constant, offset: 0, line: 0, metadata: ConstantMetadata(value: .int(20))),
			Instruction(path: chunk.path, opcode: .constant, offset: 2, line: 0, metadata: ConstantMetadata(value: .int(10))),
			Instruction(path: chunk.path, opcode: .add, offset: 4, line: 0, metadata: .simple),

			Instruction(path: chunk.path, opcode: .pop, offset: 5, line: 0, metadata: .simple),
			Instruction(path: chunk.path, opcode: .return, offset: 6, line: 0, metadata: .simple),
		]

		try #expect(chunk.disassemble() == instructions)
	}

	@Test("Def expr") func defExpr() throws {
		let chunk = try compile("""
		let i = 0
		i = 123
		""")

		try #expect(chunk.disassemble() == Instructions(
			.op(.constant, line: 0, .constant(.int(0))),
			.op(.setModuleValue, line: 0, .global(.value("CompilerTests", "i"))),
			.op(.constant, line: 1, .constant(.int(123))),
			.op(.setModuleValue, line: 1, .global(.value("CompilerTests", "i"))),
			.op(.return, line: 0)
		))
	}

	@Test("Var expr") func varExpr() throws {
		let chunk = try compile("""
		let x = 123
		x
		let y = 456
		y
		""")

		try #expect(chunk.disassemble() == Instructions(
			.op(.constant, line: 0, .constant(.int(123))),
			.op(.setModuleValue, line: 0, .global(.value("CompilerTests", "x"))),
			.op(.getModuleValue, line: 1, .global(.value("CompilerTests", "x"))),
			.op(.pop, line: 1, .simple),

			.op(.constant, line: 2, .constant(.int(456))),
			.op(.setModuleValue, line: 2, .global(.value("CompilerTests", "y"))),
			.op(.getModuleValue, line: 3, .global(.value("CompilerTests", "y"))),
			.op(.pop, line: 3, .simple),

			.op(.return, line: 0, .simple)
		))
	}

	@Test("while loops") func whileLoops() throws {
		let chunk = try compile("""
		var i = 0
		while i < 5 {
			i = i + 1
		}
		""")

		try #expect(chunk.disassemble() == Instructions(
			.op(.constant, line: 0, .constant(.int(0))),
			.op(.setModuleValue, line: 0, .global(.value("CompilerTests", "i"))),

			// Condition
			.op(.constant, line: 1, .constant(.int(5))),
			.op(.getModuleValue, line: 1, .global(.value("CompilerTests", "i"))),
			.op(.less, line: 1, .simple),

			// Jump that skips the body if the condition isn't true
			.op(.jumpUnless, line: 1, .jump(offset: 11)),

			// Pop the condition
			.op(.pop, line: 1, .simple),

			// Body
			.op(.constant, line: 2, .constant(.int(1))),
			.op(.getModuleValue, line: 2, .global(.value("CompilerTests", "i"))),
			.op(.add, line: 2, .simple),
			.op(.setModuleValue, line: 2, .global(.value("CompilerTests", "i"))),
			.op(.loop, line: 3, .loop(back: 19)),

			.op(.pop, line: 1, .simple),
			.op(.return, line: 0, .simple)
		))
	}

	@Test("If stmt") func ifStmt() throws {
		let chunk = try compile("""
		if false {
			123
		} else {
			456
		}
		""")

		try #expect(chunk.disassemble() == Instructions(
			// The condition
			.op(.false, line: 0, .simple),
			// How far to jump if the condition is false
			.op(.jumpUnless, line: 0, .jump(offset: 7)),
			.op(.pop, line: 0, .simple),

			// If we're not jumping, here's the value of the consequence block
			.op(.constant, line: 1, .constant(.int(123))),
			.op(.pop, line: 1, .simple),

			// If the condition was true, we want to jump over the alernative block
			.op(.jump, line: 2, .jump(offset: 4)),
			.op(.pop, line: 0, .simple),

			// If the condition was false, we jumped here
			.op(.constant, line: 3, .constant(.int(456))),
			.op(.pop, line: 3, .simple),

			.op(.return, line: 0, .simple)
		))
	}

	@Test("Func expr") func funcExpr() throws {
		_ = try compile("""
		func() {
			123
		}
		""")

		let chunk = module.compiledChunks[.function("CompilerTests", "1.tlk", [])]!
		let subchunk = module.compiledChunks[.function("CompilerTests", "_fn__15", [])]!

		#expect(disassemble(chunk) == Instructions(
			.op(.defClosure, line: 0, .closure(name: "_fn__15", arity: 0, depth: 0)),
			.op(.return, line: 0, .simple)
		))

		#expect(disassemble(subchunk) == Instructions(
			.op(.constant, line: 1, .constant(.int(123))),
			.op(.return, line: 1),
			.op(.return, line: 2)
		))
	}

	@Test("Call expr") func callExpr() throws {
		let chunk = try compile("""
		func() {
			123
		}()
		""")

		#expect(disassemble(chunk) == Instructions(
			.op(.defClosure, line: 0, .closure(name: "_fn__16", arity: 0, depth: 0)),
			.op(.call, line: 0, .simple),
			.op(.return, line: 0, .simple)
		))
	}

	@Test("Modifying upvalues") func modifyUpvalue() throws {
		try compile(
			"""
			func() {
				var a = 10

				func() {
					a = 20
				}()

				return a
			}
			"""
		)

		let chunk = module.compiledChunks[.function("CompilerTests", "_fn__58", [])]!
		#expect(disassemble(chunk) == Instructions(
			.op(.constant, line: 1, .constant(.int(10))),
			.op(.setLocal, line: 1, .local(.value("CompilerTests", "a"))),
			.op(.defClosure, line: 3, .closure(name: "_fn__44", arity: 0, depth: 1)),
			.op(.call, line: 3),
			.op(.getLocal, line: 7, .local(.value("CompilerTests", "a"))),
			.op(.return, line: 7),
			.op(.return, line: 8)
		))

		let subchunk = module.compiledChunks[.function("CompilerTests", "_fn__44", [])]!
		#expect(disassemble(subchunk) == Instructions(
			.op(.constant, line: 4, .constant(.int(20))),
			.op(.setCapture, line: 4, .capture(name: "a", .stack(1))),
			.op(.return, line: 4),
			.op(.return, line: 5) // func return
		))
	}

	@Test("Non-capturing upvalue") func upvalue() throws {
		// Using two locals in this test to make sure slot indexes get updated correctly
		try compile("""
		func() {
			let a = 123
			let b = 456
			func() {
				a
				b
			}
		}
		""")

		let result = disassemble(module.compiledChunks[.function("CompilerTests", "_fn__57", [])]!)
		let expected = Instructions(
			.op(.constant, line: 1, .constant(.int(123))),
			.op(.setLocal, line: 1, .local(.value("CompilerTests", "a"))),

			.op(.constant, line: 2, .constant(.int(456))),
			.op(.setLocal, line: 2, .local(.value("CompilerTests", "b"))),

			.op(.defClosure, line: 3, .closure(
				name: "_fn__56",
				arity: 0,
				depth: 1
			)),

			.op(.pop, line: 3, .simple),
			.op(.return, line: 7, .simple)
		)

		#expect(result == expected)

		let subchunk = module.compiledChunks[.function("CompilerTests", "_fn__56", [])]!
		let subexpected = Instructions(
			.op(.getCapture, line: 4, .capture(name: "a", .stack(1))),
			.op(.pop, line: 4, .simple),
			.op(.getCapture, line: 5, .capture(name: "b", .stack(1))),
			.op(.pop, line: 5, .simple),
			.op(.return, line: 6, .simple)
		)

		try #expect(subchunk.disassemble() == subexpected)
	}

	@Test("Cleans up locals") func cleansUpLocals() throws {
		_ = try compile("""
		func() {
			let a = 123
			func() {
				let b = 456
				return a + b
			}
		}
		""")

		let chunk = module.compiledChunks[.function("CompilerTests", "_fn__65", [])]!

		let result = disassemble(chunk)
		let expected = Instructions(
			.op(.constant, line: 1, .constant(.int(123))),
			.op(.setLocal, line: 1, .local(.value("CompilerTests", "a"))),
			.op(.defClosure, line: 2, .closure(name: "_fn__64", arity: 0, depth: 1)),
			.op(.pop, line: 2),
			.op(.return, line: 6, .simple)
		)

		#expect(result == expected)

		let subchunk = module.compiledChunks[.function("CompilerTests", "_fn__64", [])]!
		let subexpected = Instructions(
			// Define 'b'
			.op(.constant, line: 3, .constant(.int(456))),
			.op(.setLocal, line: 3, .local(.value("CompilerTests", "b"))),

			// Get 'b' to add to a
			.op(.getLocal, line: 4, .local(.value("CompilerTests", "b"))),
			// Get 'a' from upvalue
			.op(.getCapture, line: 4, .capture(name: "a", .stack(1))),

			// Do the addition
			.op(.add, line: 4),
			.op(.return, line: 4),

			.op(.return, line: 5)
		)

		#expect(disassemble(subchunk) == subexpected)
	}

	@Test("Struct initializer") func structs() throws {
		let chunk = try compile("""
		struct Person {
			var age: int

			init(age: int) {
				self.age = age
			}
		}

		Person(age: 123)
		""")

		#expect(disassemble(chunk) == Instructions(
			.op(.constant, line: 8, .constant(.int(123))),
			.op(.getStruct, line: 8, .struct(.struct("CompilerTests", "Person"))),
			.op(.call, line: 8, .simple),
			.op(.pop, line: 8, .simple),
			.op(.return, line: 0, .simple)
		))
	}

	@Test("Struct init with no args") func structInitNoArgs() throws {
		let chunk = try compile("""
		struct Person {
			var age: int

			init() {
				self.age = 123
			}
		}

		Person()
		""")

		#expect(disassemble(chunk) == Instructions(
			.op(.getStruct, line: 8, .struct(.struct("CompilerTests", "Person"))),
			.op(.call, line: 8, .simple),
			.op(.pop, line: 8, .simple),
			.op(.return, line: 0, .simple)
		))
	}

	@Test("Struct property getter") func structsProperties() throws {
		let chunk = try compile("""
		struct Person {
			var age: int

			init(age: int) { self.age = age }
		}

		Person(age: 123).age
		""")

		try #expect(chunk.disassemble() == Instructions(
			.op(.constant, line: 6, .constant(.int(123))),
			.op(.getStruct, line: 6, .struct(.struct("CompilerTests", "Person"))),
			.op(.call, line: 6, .simple),
			.op(.getProperty, line: 6, .getProperty(.property("CompilerTests", "Person", "age"), options: [])),
			.op(.pop, line: 6, .simple),
			.op(.return, line: 0, .simple)
		))
	}

	@Test("Struct methods") func structMethods() throws {
		let chunk = try compile("""
		struct Person {
			var age: int

			init(age: int) { self.age = age }

			func getAge() {
				self.age
			}
		}

		Person(age: 123).getAge()
		""")

		#expect(try disassemble(chunk) == Instructions(
			.op(.constant, line: 10, .constant(.int(123))),
			.op(.getStruct, line: 10, .struct(.struct("CompilerTests", "Person"))),
			.op(.call, line: 10, .simple),
			.op(.getProperty, line: 10, .getProperty(.method("CompilerTests", "Person", "getAge", []), options: .isMethod)),
			.op(.call, line: 10, .simple),
			.op(.pop, line: 10, .simple),
			.op(.return, line: 0, .simple)
		))
	}
}
