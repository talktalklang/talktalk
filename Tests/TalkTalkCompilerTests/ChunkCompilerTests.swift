//
//  CompilerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkAnalysis
import TalkTalkSyntax
import Testing

@MainActor
struct CompilerTests {
	func compile(_ string: String, inModule: Bool = false) throws -> Chunk {
		let parsed = try Parser.parse(string)
		let analyzed = try! SourceFileAnalyzer.analyze(parsed, in: .init())
		let analysisModule = inModule ? try! ModuleAnalyzer(name: "CompilerTests", files: [.tmp(string)], moduleEnvironment: [:]).analyze() : .empty("CompilerTests")
		var compiler = SourceFileCompiler(name: "CompilerTests", analyzedSyntax: analyzed)
		return try compiler.compile(in: CompilingModule(name: "CompilerTests", analysisModule: analysisModule, moduleEnvironment: [:]))
	}

	@Test("Empty program") func empty() throws {
		let chunk = try compile("")
		#expect(chunk.disassemble()[0].opcode == .return)
	}

	@Test("Int literal") func intLiteral() throws {
		let chunk = try compile("123")

		let instructions = [
			Instruction(opcode: .constant, offset: 0, line: 0, metadata: ConstantMetadata(value: .int(123))),
			Instruction(opcode: .pop, offset: 2, line: 0, metadata: .simple),
			Instruction(opcode: .return, offset: 2, line: 0, metadata: .simple)
		]

		#expect(chunk.disassemble() == instructions)
	}

	@Test("Binary int op") func binaryIntOp() throws {
		let chunk = try compile("10 + 20")

		let instructions = [
			Instruction(opcode: .constant, offset: 0, line: 0, metadata: ConstantMetadata(value: .int(20))),
			Instruction(opcode: .constant, offset: 2, line: 0, metadata: ConstantMetadata(value: .int(10))),
			Instruction(opcode: .add, offset: 4, line: 0, metadata: .simple),

			Instruction(opcode: .pop, offset: 5, line: 0, metadata: .simple),
			Instruction(opcode: .return, offset: 6, line: 0, metadata: .simple)
		]

		#expect(chunk.disassemble() == instructions)
	}

	@Test("Static string") func staticString() throws {
		let chunk = try compile("""
		"hello "
		"world"
		""")

		var string1 = "hello ".utf8CString
		let pointer1 = string1.withUnsafeMutableBufferPointer { $0 }

		var string2 = "world".utf8CString
		let pointer2 = string2.withUnsafeMutableBufferPointer { $0 }

		chunk.data = Object.string(pointer1).bytes + Object.string(pointer2).bytes

		let result = chunk.disassemble()
		let expected = [
			Instruction(opcode: .constant, offset: 0, line: 0, metadata: ConstantMetadata(value: .data(0))),
			Instruction(opcode: .pop, offset: 2, line: 0, metadata: .simple),
			Instruction(opcode: .constant, offset: 3, line: 1, metadata: ConstantMetadata(value: .data(8))),
			Instruction(opcode: .pop, offset: 5, line: 1, metadata: .simple),
			Instruction(opcode: .return, offset: 6, line: 0, metadata: .simple)
		]

		#expect(result == expected)
	}

	@Test("Def expr") func defExpr() throws {
		let chunk = try compile("""
		i = 123
		""", inModule: true)

		#expect(chunk.disassemble() == [
			Instruction(opcode: .constant, offset: 0, line: 0, metadata: .constant(.int(123))),
			Instruction(opcode: .setModuleValue, offset: 2, line: 0, metadata: .global(slot: 0)),
			Instruction(opcode: .pop, offset: 4, line: 0, metadata: .simple),
			Instruction(opcode: .return, offset: 5, line: 0, metadata: .simple)
		])
	}

	@Test("Var expr") func varExpr() throws {
		let chunk = try compile("""
		x = 123
		x
		y = 456
		y
		""", inModule: true)

		#expect(chunk.disassemble() == [
			Instruction(opcode: .constant, offset: 0, line: 0, metadata: .constant(.int(123))),
			Instruction(opcode: .setModuleValue, offset: 2, line: 0, metadata: .global(slot: 0)),
			Instruction(opcode: .pop, offset: 4, line: 0, metadata: .simple),

			Instruction(opcode: .getModuleValue, offset: 5, line: 1, metadata: .global(slot: 0)),
			Instruction(opcode: .pop, offset: 7, line: 1, metadata: .simple),

			Instruction(opcode: .constant, offset: 8, line: 2, metadata: .constant(.int(456))),
			Instruction(opcode: .setModuleValue, offset: 10, line: 2, metadata: .global(slot: 1)),
			Instruction(opcode: .pop, offset: 12, line: 2, metadata: .simple),

			Instruction(opcode: .getModuleValue, offset: 13, line: 3, metadata: .global(slot: 1)),
			Instruction(opcode: .pop, offset: 15, line: 3, metadata: .simple),

			Instruction(opcode: .return, offset: 16, line: 0, metadata: .simple)
		])
	}

	@Test("while loops") func whileLoops() throws {
		let chunk = try compile("""
		i = 0
		while i < 5 {
			i = i + 1
		}
		""")

		#expect(chunk.disassemble() == [
			Instruction(opcode: .constant, offset: 0, line: 0, metadata: .constant(.int(0))),
			Instruction(opcode: .setLocal, offset: 2, line: 0, metadata: .local(slot: 1, name: "i")),
			Instruction(opcode: .pop, offset: 4, line: 0, metadata: .simple),

			// Condition
			Instruction(opcode: .constant, offset: 5, line: 1, metadata: .constant(.int(5))),
			Instruction(opcode: .getLocal, offset: 7, line: 1, metadata: .local(slot: 1, name: "i")),
			Instruction(opcode: .less, offset: 9, line: 1, metadata: .simple),

			// Jump that skips the body if the condition isn't true
			Instruction(opcode: .jumpUnless, offset: 10, line: 1, metadata: .jump(offset: 12)),

			// Pop condition off the stack
			Instruction(opcode: .pop, offset: 13, line: 1, metadata: .simple),

			// Body
			Instruction(opcode: .constant, offset: 14, line: 2, metadata: .constant(.int(1))),
			Instruction(opcode: .getLocal, offset: 16, line: 2, metadata: .local(slot: 1, name: "i")),
			Instruction(opcode: .add, offset: 18, line: 2, metadata: .simple),
			Instruction(opcode: .setLocal, offset: 19, line: 2, metadata: .local(slot: 1, name: "i")),
			Instruction(opcode: .pop, offset: 21, line: 2, metadata: .simple),
			Instruction(opcode: .loop, offset: 22, line: 3, metadata: .loop(back: 20)),
			Instruction(opcode: .pop, offset: 25, line: 1, metadata: .simple),
			Instruction(opcode: .return, offset: 22, line: 0, metadata: .simple)
		])
	}

	@Test("If expr") func ifExpr() throws {
		let chunk = try compile("""
		if false {
			123
		} else {
			456
		}
		""")

		#expect(chunk.disassemble() == [
			// The condition
			Instruction(opcode: .false, offset: 0, line: 0, metadata: .simple),
			// How far to jump if the condition is false
			Instruction(opcode: .jumpUnless, offset: 1, line: 0, metadata: .jump(offset: 7)),
			// Pop the condition
			Instruction(opcode: .pop, offset: 4, line: 0, metadata: .simple),

			// If we're not jumping, here's the value of the consequence block
			Instruction(opcode: .constant, offset: 5, line: 1, metadata: .constant(.int(123))),
			Instruction(opcode: .pop, offset: 7, line: 1, metadata: .simple),

			// If the condition was true, we want to jump over the alernative block
			Instruction(opcode: .jump, offset: 8, line: 2, metadata: .jump(offset: 4)),


			Instruction(opcode: .pop, offset: 11, line: 0, metadata: .simple),

			// If the condition was false, we jumped here
			Instruction(opcode: .constant, offset: 12, line: 3, metadata: .constant(.int(456))),

			Instruction(opcode: .pop, offset: 14, line: 3, metadata: .simple),

			// DOUBLE POPS??
			Instruction(opcode: .pop, offset: 15, line: 0, metadata: .simple),

			// return the result
			Instruction(opcode: .return, offset: 16, line: 0, metadata: .simple)
		])
	}

	@Test("Func expr") func funcExpr() throws {
		let chunk = try compile("""
		func() {
			123
		}
		""")

		let subchunk = chunk.getChunk(at: 0)

		#expect(chunk.disassemble() == [
			Instruction(opcode: .defClosure, offset: 0, line: 0, metadata: .closure(arity: 0, depth: 0)),
			Instruction(opcode: .pop, offset: 2, line: 0, metadata: .simple),
			Instruction(opcode: .return, offset: 3, line: 0, metadata: .simple)
		])

		#expect(subchunk.disassemble() == [
			Instruction(opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(123))),
			Instruction(opcode: .pop, offset: 2, line: 1, metadata: .simple),
			Instruction(opcode: .return, offset: 3, line: 2, metadata: .simple)
		])
	}

	@Test("Call expr") func callExpr() throws {
		let chunk = try compile("""
		func() {
			123
		}()
		""")

		#expect(chunk.disassemble() == [
			Instruction(opcode: .defClosure, offset: 0, line: 0, metadata: .closure(arity: 0, depth: 0)),
			Instruction(opcode: .call, offset: 2, line: 2, metadata: .simple),
			Instruction(opcode: .pop, offset: 3, line: 2, metadata: .simple),
			Instruction(opcode: .return, offset: 4, line: 0, metadata: .simple),
		])
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
		let expected = [
			Instruction(opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(123))),
			Instruction(opcode: .setLocal, offset: 2, line: 1, metadata: .local(slot: 1, name: "a")),
			Instruction(opcode: .pop, offset: 4, line: 1, metadata: .simple),

			Instruction(opcode: .constant, offset: 5, line: 2, metadata: .constant(.int(456))),
			Instruction(opcode: .setLocal, offset: 7, line: 2, metadata: .local(slot: 2, name: "b")),
			Instruction(opcode: .pop, offset: 9, line: 2, metadata: .simple),

			Instruction(opcode: .defClosure, offset: 10, line: 3, metadata: .closure(arity: 0, depth: 1, upvalues: [.capturing(1), .capturing(2)])),
			Instruction(opcode: .pop, offset: 16, line: 3, metadata: .simple),
			Instruction(opcode: .return, offset: 17, line: 7, metadata: .simple),
		]

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
		let expected = [
			Instruction(opcode: .constant, offset: 0, line: 0, metadata: .constant(.int(123))),
			Instruction(opcode: .setLocal, offset: 2, line: 0, metadata: .local(slot: 1, name: "a")),
			Instruction(opcode: .pop, offset: 4, line: 0, metadata: .simple),
			Instruction(opcode: .defClosure, offset: 5, line: 1, metadata: .closure(arity: 0, depth: 0, upvalues: [.capturing(1)])),
			Instruction(opcode: .pop, offset: 9, line: 1, metadata: .simple),
			Instruction(opcode: .return, offset: 10, line: 0, metadata: .simple),
		]

		#expect(result == expected)

		let subchunk = chunk.getChunk(at: 0)

		#expect(subchunk.upvalueCount == 1)

		let subexpected = [
			// Define 'b'
			Instruction(opcode: .constant, offset: 0, line: 2, metadata: .constant(.int(456))),
			Instruction(opcode: .setLocal, offset: 2, line: 2, metadata: .local(slot: 1, name: "b")),
			Instruction(opcode: .pop, offset: 4, line: 2, metadata: .simple),

			// Get 'b' to add to a
			Instruction(opcode: .getLocal, offset: 5, line: 3, metadata: .local(slot: 1, name: "b")),
			// Get 'a' from upvalue
			Instruction(opcode: .getUpvalue, offset: 7, line: 3, metadata: .upvalue(slot: 0, name: "a")),
			// Do the addition
			Instruction(opcode: .add, offset: 9, line: 3, metadata: .simple),
			Instruction(opcode: .pop, offset: 10, line: 3, metadata: .simple),

			Instruction(opcode: .return, offset: 11, line: 4, metadata: .simple),
		]

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

		#expect(chunk.disassemble() == [
			Instruction(opcode: .pop, offset: 0, line: 0, metadata: .simple),
			Instruction(opcode: .constant, offset: 1, line: 8, metadata: .constant(.int(123))),
			Instruction(opcode: .getStruct, offset: 3, line: 8, metadata: .struct(slot: 0)),
			Instruction(opcode: .call, offset: 5, line: 8, metadata: .simple),
			Instruction(opcode: .pop, offset: 6, line: 8, metadata: .simple),
			Instruction(opcode: .return, offset: 7, line: 0, metadata: .simple)
		])
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

		#expect(chunk.disassemble() == [
			Instruction(opcode: .pop, offset: 0, line: 0, metadata: .simple),
			Instruction(opcode: .getStruct, offset: 1, line: 8, metadata: .struct(slot: 0)),
			Instruction(opcode: .call, offset: 2, line: 8, metadata: .simple),
			Instruction(opcode: .pop, offset: 3, line: 8, metadata: .simple),
			Instruction(opcode: .return, offset: 3, line: 0, metadata: .simple)
		])
	}

	@Test("Struct property getter") func structsProperties() throws {
		let chunk = try compile("""
		struct Person {
			var age: int

			init(age: int) { self.age = age }
		}

		Person(age: 123).age
		""", inModule: true)

		#expect(chunk.disassemble() == [
			Instruction(opcode: .pop, offset: 0, line: 0, metadata: .simple),
			Instruction(opcode: .constant, offset: 1, line: 6, metadata: .constant(.int(123))),
			Instruction(opcode: .getStruct, offset: 3, line: 6, metadata: .struct(slot: 0)),
			Instruction(opcode: .call, offset: 5, line: 6, metadata: .simple),
			Instruction(opcode: .getProperty, offset: 6, line: 6, metadata: .getProperty(slot: 0, options: [])),
			Instruction(opcode: .pop, offset: 9, line: 6, metadata: .simple),
			Instruction(opcode: .return, offset: 10, line: 0, metadata: .simple)
		])
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

		#expect(chunk.disassemble() == [
			Instruction(opcode: .pop, offset: 0, line: 0, metadata: .simple),
			Instruction(opcode: .constant, offset: 1, line: 10, metadata: .constant(.int(123))),
			Instruction(opcode: .getStruct, offset: 3, line: 10, metadata: .struct(slot: 0)),
			Instruction(opcode: .call, offset: 5, line: 10, metadata: .simple),
			Instruction(opcode: .getProperty, offset: 6, line: 10, metadata: .getProperty(slot: 1, options: .isMethod)),
			Instruction(opcode: .call, offset: 9, line: 10, metadata: .simple),
			Instruction(opcode: .pop, offset: 10, line: 10, metadata: .simple),
			Instruction(opcode: .return, offset: 11, line: 0, metadata: .simple)
		])
	}
}
