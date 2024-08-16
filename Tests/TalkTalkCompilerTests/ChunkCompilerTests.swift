//
//  CompilerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkSyntax
import Testing

// Helper for building instruction expectations.
// Moving stuff around always required updating a bunch of offsets
// even for unrelated stuff. This helper automatically syncs offsets
// and just requires opcode/line/metadata which tends to be more
// interesting. It uses Metadata's length field to determine how much
// to move the offset.
struct Instructions: CustomStringConvertible {
	struct Expectation {
		let opcode: Opcode
		let line: UInt32
		let metadata: any InstructionMetadata

		static func op(_ opcode: Opcode, line: UInt32, _ metadata: any InstructionMetadata) -> Expectation {
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

	var instructions: [Instruction] {
		var result: [Instruction] = []
		var i = 0

		for expectation in expectations {
			let instruction = Instruction(
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
struct CompilerTests {
	func compile(_ string: String, inModule: Bool = false) throws -> Chunk {
		let parsed = try Parser.parse(.init(path: "", text: string))
		let analyzed = try! SourceFileAnalyzer.analyze(parsed, in: .init())
		let analysisModule = inModule ? try! ModuleAnalyzer(
			name: "CompilerTests",
			files: [.tmp(string)],
			moduleEnvironment: [:],
			importedModules: []
		).analyze() : .empty("CompilerTests")
		var compiler = SourceFileCompiler(name: "CompilerTests", analyzedSyntax: analyzed)
		return try compiler.compile(in: CompilingModule(name: "CompilerTests", analysisModule: analysisModule, moduleEnvironment: [:]))
	}

	@Test("Empty program") func empty() throws {
		let chunk = try compile("")
		#expect(chunk.disassemble()[0].opcode == .return)
	}

	@Test("Int literal") func intLiteral() throws {
		let chunk = try compile("123")

		let instructions = Instructions([
			.init(opcode: .constant, line: 0, metadata: .constant(.int(123))),
			.init(opcode: .return, line: 0, metadata: .simple),
			.init(opcode: .return, line: 0, metadata: .simple),
		])

		let expected = [
			Instruction(opcode: .constant, offset: 0, line: 0, metadata: ConstantMetadata(value: .int(123))),
			Instruction(opcode: .return, offset: 2, line: 0, metadata: .simple),
			Instruction(opcode: .return, offset: 3, line: 0, metadata: .simple),
		]

		#expect(instructions.instructions == expected)
		#expect(chunk.disassemble() == instructions)
	}

	@Test("Binary int op") func binaryIntOp() throws {
		let chunk = try compile("10 + 20")

		let instructions = [
			Instruction(opcode: .constant, offset: 0, line: 0, metadata: ConstantMetadata(value: .int(20))),
			Instruction(opcode: .constant, offset: 2, line: 0, metadata: ConstantMetadata(value: .int(10))),
			Instruction(opcode: .add, offset: 4, line: 0, metadata: .simple),

			Instruction(opcode: .return, offset: 5, line: 0, metadata: .simple),
			Instruction(opcode: .return, offset: 6, line: 0, metadata: .simple),
		]

		#expect(chunk.disassemble() == instructions)
	}

	@Test("Def expr") func defExpr() throws {
		let chunk = try compile("""
		i = 123
		""", inModule: true)

		#expect(chunk.disassemble() == [
			Instruction(opcode: .constant, offset: 0, line: 0, metadata: .constant(.int(123))),
			Instruction(opcode: .setModuleValue, offset: 2, line: 0, metadata: .global(slot: 0)),
			Instruction(opcode: .return, offset: 4, line: 0, metadata: .simple),
			Instruction(opcode: .return, offset: 5, line: 0, metadata: .simple),
		])
	}

	@Test("Var expr") func varExpr() throws {
		let chunk = try compile("""
		x = 123
		x
		y = 456
		y
		""", inModule: true)

		#expect(chunk.disassemble() == Instructions(
			.op(.constant, line: 0, .constant(.int(123))),
			.op(.setModuleValue, line: 0, .global(slot: 0)),
			.op(.pop, line: 0, .simple),

			.op(.getModuleValue, line: 1, .global(slot: 0)),
			.op(.pop, line: 1, .simple),

			.op(.constant, line: 2, .constant(.int(456))),
			.op(.setModuleValue, line: 2, .global(slot: 1)),
			.op(.pop, line: 2, .simple),

			.op(.getModuleValue, line: 3, .global(slot: 1)),
			.op(.pop, line: 3, .simple),

			.op(.return, line: 0, .simple)
		))
	}

	@Test("while loops") func whileLoops() throws {
		let chunk = try compile("""
		i = 0
		while i < 5 {
			i = i + 1
		}
		""")

		#expect(chunk.disassemble() == Instructions(
			.op(.constant, line: 0, .constant(.int(0))),
			.op(.setLocal, line: 0, .local(slot: 1, name: "i")),
			.op(.pop, line: 0, .simple),

			// Condition
			.op(.constant, line: 1, .constant(.int(5))),
			.op(.getLocal, line: 1, .local(slot: 1, name: "i")),
			.op(.less, line: 1, .simple),

			// Jump that skips the body if the condition isn't true
			.op(.jumpUnless, line: 1, .jump(offset: 12)),

			// Pop the condition
			.op(.pop, line: 1, .simple),

			// Body
			.op(.constant, line: 2, .constant(.int(1))),
			.op(.getLocal, line: 2, .local(slot: 1, name: "i")),
			.op(.add, line: 2, .simple),
			.op(.setLocal, line: 2, .local(slot: 1, name: "i")),
			.op(.pop, line: 2, .simple),
			.op(.loop, line: 3, .loop(back: 20)),

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

		#expect(chunk.disassemble() == Instructions(
			// The condition
			.op(.false, line: 0, .simple),
			// How far to jump if the condition is false
			.op(.jumpUnless, line: 0, .jump(offset: 7)),
			// Pop the condition
			.op(.pop, line: 0, .simple),

			// If we're not jumping, here's the value of the consequence block
			.op(.constant, line: 1, .constant(.int(123))),
			.op(.pop, line: 1, .simple),

			// If the condition was true, we want to jump over the alernative block
			.op(.jump, line: 2, .jump(offset: 3)),

			// If the condition was false, we jumped here
			.op(.constant, line: 3, .constant(.int(456))),
			.op(.pop, line: 3, .simple),

			.op(.return, line: 0, .simple)
		))
	}

	@Test("Func expr") func funcExpr() throws {
		let chunk = try compile("""
		func() {
			123
		}
		""")

		let subchunk = chunk.getChunk(at: 0)

		#expect(chunk.disassemble() == Instructions(
			.op(.defClosure, line: 0, .closure(arity: 0, depth: 0)),
			.op(.return, line: 0, .simple)
		))

		#expect(subchunk.disassemble() == Instructions(
			.op(.constant, line: 1, .constant(.int(123))),
			.op(.return, line: 1, .simple),
			.op(.return, line: 2, .simple)
		))
	}

	@Test("Call expr") func callExpr() throws {
		let chunk = try compile("""
		func() {
			123
		}()
		""")

		#expect(chunk.disassemble() == Instructions(
			.op(.defClosure, line: 0, .closure(arity: 0, depth: 0)),
			.op(.call, line: 2, .simple),
			.op(.return, line: 0, .simple)
		))
	}

	@Test("Non-capturing upvalue") func upvalue() throws {
		// Using two locals in this test to make sure slot indexes get updated correctly
		let chunk = try compile("""
		func() {
			a = 123
			b = 456
			func() {
				a
				b
			}
		}
		""")

		let result = chunk.getChunk(at: 1).disassemble()
		let expected = Instructions(
			.op(.constant, line: 1, .constant(.int(123))),
			.op(.setLocal, line: 1, .local(slot: 1, name: "a")),
			.op(.pop, line: 1, .simple),

			.op(.constant, line: 2, .constant(.int(456))),
			.op(.setLocal, line: 2, .local(slot: 2, name: "b")),
			.op(.pop, line: 2, .simple),

			.op(.defClosure, line: 3, .closure(
				arity: 0,
				depth: 1,
				upvalues: [.capturing(1), .capturing(2)]
			)),
			.op(.return, line: 7, .simple)
		)

		#expect(result == expected)

		let subchunk = chunk.getChunk(at: 1).getChunk(at: 0)
		let subexpected = [
			Instruction(opcode: .getUpvalue, offset: 0, line: 4, metadata: .upvalue(slot: 0, name: "a")),
			Instruction(opcode: .pop, offset: 2, line: 4, metadata: .simple),
			Instruction(opcode: .getUpvalue, offset: 3, line: 5, metadata: .upvalue(slot: 1, name: "b")),
			Instruction(opcode: .pop, offset: 5, line: 5, metadata: .simple),
			Instruction(opcode: .return, offset: 7, line: 7, metadata: .simple),
		]

		#expect(subchunk.disassemble() == subexpected)
	}

	@Test("Cleans up locals") func cleansUpLocals() throws {
		let chunk = try compile("""
		a = 123
		func() {
			b = 456
			a + b
		}
		""", inModule: false)

		let result = chunk.disassemble()
		let expected = Instructions(
			.op(.constant, line: 0, .constant(.int(123))),
			.op(.setLocal, line: 0, .local(slot: 1, name: "a")),
			.op(.pop, line: 0, .simple),
			.op(.defClosure, line: 1, .closure(arity: 0, depth: 0, upvalues: [.capturing(1)])),
			.op(.return, line: 0, .simple)
		)

		#expect(result == expected)

		let subchunk = chunk.getChunk(at: 0)

		#expect(subchunk.upvalueCount == 1)

		let subexpected = Instructions(
			// Define 'b'
			.op(.constant, line: 2, .constant(.int(456))),
			.op(.setLocal, line: 2, .local(slot: 1, name: "b")),
			.op(.pop, line: 2, .simple),

			// Get 'b' to add to a
			.op(.getLocal, line: 3, .local(slot: 1, name: "b")),
			// Get 'a' from upvalue
			.op(.getUpvalue, line: 3, .upvalue(slot: 0, name: "a")),

			// Do the addition
			.op(.add, line: 3, .simple),
			.op(.pop, line: 3, .simple),

			.op(.return, line: 4, .simple)
		)

		#expect(subchunk.disassemble() == subexpected)
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
		""", inModule: true)

		#expect(chunk.disassemble() == Instructions(
			.op(.constant, line: 8, .constant(.int(123))),
			.op(.getStruct, line: 8, .struct(slot: 0)),
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
		""", inModule: true)

		#expect(chunk.disassemble() == Instructions(
			.op(.getStruct, line: 8, .struct(slot: 0)),
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
		""", inModule: true)

		#expect(chunk.disassemble() == Instructions(
			.op(.constant, line: 6, .constant(.int(123))),
			.op(.getStruct, line: 6, .struct(slot: 0)),
			.op(.call, line: 6, .simple),
			.op(.getProperty, line: 6, .getProperty(slot: 0, options: [])),
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
		""", inModule: true)

		#expect(chunk.disassemble() == Instructions(
			.op(.constant, line: 10, .constant(.int(123))),
			.op(.getStruct, line: 10, .struct(slot: 0)),
			.op(.call, line: 10, .simple),
			.op(.getProperty, line: 10, .getProperty(slot: 1, options: .isMethod)),
			.op(.call, line: 10, .simple),
			.op(.pop, line: 10, .simple),
			.op(.return, line: 0, .simple)
		))
	}
}
