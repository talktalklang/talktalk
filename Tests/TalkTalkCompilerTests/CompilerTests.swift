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

struct CompilerTests {
	func compile(_ string: String) -> Chunk {
		let parsed = Parser.parse(string)
		let analyzed = try! Analyzer.analyzedExprs(parsed)
		var compiler = Compiler(analyzedExprs: analyzed)
		return try! compiler.compile()
	}

	@Test("Empty program") func empty() {
		let chunk = compile("")
		#expect(chunk.disassemble()[0].opcode == .return)
	}

	@Test("Int literal") func intLiteral() {
		let chunk = compile("123")

		let instructions = [
			Instruction(opcode: .constant, offset: 0, line: 1, metadata: ConstantMetadata(value: .int(123))),
			Instruction(opcode: .return, offset: 2, line: 0, metadata: .simple)
		]

		#expect(chunk.disassemble() == instructions)
	}

	@Test("Binary int op") func binaryIntOp() {
		let chunk = compile("10 + 20")

		let instructions = [
			Instruction(opcode: .constant, offset: 0, line: 1, metadata: ConstantMetadata(value: .int(20))),
			Instruction(opcode: .constant, offset: 2, line: 1, metadata: ConstantMetadata(value: .int(10))),
			Instruction(opcode: .add, offset: 4, line: 1, metadata: .simple),
			Instruction(opcode: .return, offset: 5, line: 0, metadata: .simple)
		]

		#expect(chunk.disassemble() == instructions)
	}

	@Test("Static string") func staticString() {
		let chunk = compile("""
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
			Instruction(opcode: .constant, offset: 0, line: 1, metadata: ConstantMetadata(value: .data(0))),
			Instruction(opcode: .constant, offset: 2, line: 2, metadata: ConstantMetadata(value: .data(8))),
			Instruction(opcode: .return, offset: 4, line: 0, metadata: .simple)
		]

		#expect(result == expected)
	}

	@Test("Def expr") func defExpr() {
		let chunk = compile("""
		i = 123
		""")

		#expect(chunk.disassemble() == [
			Instruction(opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(123))),
			Instruction(opcode: .setLocal, offset: 2, line: 1, metadata: .local(slot: 1, name: "i")),
			Instruction(opcode: .return, offset: 4, line: 0, metadata: .simple)
		])
	}

	@Test("Var expr") func varExpr() {
		let chunk = compile("""
		x = 123
		x
		y = 456
		y
		""")

		chunk.dump()

		#expect(chunk.disassemble() == [
			Instruction(opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(123))),
			Instruction(opcode: .setLocal, offset: 2, line: 1, metadata: .local(slot: 1, name: "x")),
			Instruction(opcode: .getLocal, offset: 4, line: 2, metadata: .local(slot: 1, name: "x")),
			Instruction(opcode: .constant, offset: 6, line: 3, metadata: .constant(.int(456))),
			Instruction(opcode: .setLocal, offset: 8, line: 3, metadata: .local(slot: 2, name: "y")),
			Instruction(opcode: .getLocal, offset: 10, line: 4, metadata: .local(slot: 2, name: "y")),
			Instruction(opcode: .return, offset: 12, line: 0, metadata: .simple)
		])
	}

	@Test("If expr") func ifExpr() {
		let chunk = compile("""
		if false {
			123
		} else {
			456
		}
		""")

		#expect(chunk.disassemble() == [
			// The condition
			Instruction(opcode: .false, offset: 0, line: 1, metadata: .simple),
			// How far to jump if the condition is false
			Instruction(opcode: .jumpUnless, offset: 1, line: 1, metadata: .jump(offset: 6)),
			// Pop the condition
			Instruction(opcode: .pop, offset: 4, line: 1, metadata: .simple),

			// If we're not jumping, here's the value of the consequence block
			Instruction(opcode: .constant, offset: 7, line: 2, metadata: .constant(.int(123))),
			// If the condition was true, we want to jump over the alernative block
			Instruction(opcode: .jump, offset: 10, line: 3, metadata: .jump(offset: 3)),
			// Pop the condition
			Instruction(opcode: .pop, offset: 10, line: 1, metadata: .simple),

			// If the condition was false, we jumped here
			Instruction(opcode: .constant, offset: 7, line: 4, metadata: .constant(.int(456))),

			// return the result
			Instruction(opcode: .return, offset: 5, line: 0, metadata: .simple)
		])
	}

	@Test("Func expr") func funcExpr() {
		let chunk = compile("""
		func() {
			123
		}
		""")

		let subchunk = chunk.getChunk(at: 0)

		#expect(chunk.disassemble() == [
			Instruction(opcode: .defClosure, offset: 0, line: 1, metadata: .closure(arity: 0, depth: 0)),
			Instruction(opcode: .return, offset: 2, line: 0, metadata: .simple)
		])

		#expect(subchunk.disassemble() == [
			Instruction(opcode: .constant, offset: 0, line: 2, metadata: .constant(.int(123))),
			Instruction(opcode: .return, offset: 2, line: 3, metadata: .simple)
		])
	}

	@Test("Call expr") func callExpr() {
		let chunk = compile("""
		func() {
			123
		}()
		""")

		chunk.dump()

		#expect(chunk.disassemble() == [
			Instruction(opcode: .defClosure, offset: 0, line: 1, metadata: .closure(arity: 0, depth: 0)),
			Instruction(opcode: .call, offset: 2, line: 3, metadata: .simple),
			Instruction(opcode: .return, offset: 3, line: 0, metadata: .simple),
		])
	}

	@Test("Non-capturing upvalue") func upvalue() {
		// Using two locals in this test to make sure slot indexes get updated correctly
		let chunk = compile("""
		a = 123
		b = 456
		func() {
			a
			b
		}
		""")

		let result = chunk.disassemble()
		let expected = [
			Instruction(opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(123))),
			Instruction(opcode: .setLocal, offset: 2, line: 1, metadata: .local(slot: 1, name: "a")),
			Instruction(opcode: .constant, offset: 4, line: 2, metadata: .constant(.int(456))),
			Instruction(opcode: .setLocal, offset: 6, line: 2, metadata: .local(slot: 2, name: "b")),
			Instruction(opcode: .defClosure, offset: 8, line: 3, metadata: .closure(arity: 0, depth: 0, upvalues: [.capturing(1), .capturing(2)])),
			Instruction(opcode: .return, offset: 14, line: 0, metadata: .simple),
		]

		#expect(result == expected)

		let subchunk = chunk.getChunk(at: 0)
		let subexpected = [
			Instruction(opcode: .getUpvalue, offset: 0, line: 4, metadata: .upvalue(slot: 0, name: "a")),
			Instruction(opcode: .getUpvalue, offset: 2, line: 5, metadata: .upvalue(slot: 1, name: "b")),
			Instruction(opcode: .return, offset: 6, line: 6, metadata: .simple),
		]

		#expect(subchunk.disassemble() == subexpected)
	}

	@Test("Cleans up locals") func cleansUpLocals() {
		let chunk = compile("""
		a = 123
		func() {
			b = 456
			a + b
		}
		""")

		let result = chunk.disassemble()
		let expected = [
			Instruction(opcode: .constant, offset: 0, line: 1, metadata: .constant(.int(123))),
			Instruction(opcode: .setLocal, offset: 2, line: 1, metadata: .local(slot: 1, name: "a")),
			Instruction(opcode: .defClosure, offset: 4, line: 2, metadata: .closure(arity: 0, depth: 0, upvalues: [.capturing(1)])),
			Instruction(opcode: .return, offset: 6, line: 0, metadata: .simple),
		]

		#expect(result == expected)

		let subchunk = chunk.getChunk(at: 0)

		#expect(subchunk.upvalueCount == 1)

		let subexpected = [
			// Define 'b'
			Instruction(opcode: .constant, offset: 0, line: 3, metadata: .constant(.int(456))),
			Instruction(opcode: .setLocal, offset: 2, line: 3, metadata: .local(slot: 1, name: "b")),

			// Get 'b' to add to a
			Instruction(opcode: .getLocal, offset: 4, line: 4, metadata: .local(slot: 1, name: "b")),
			// Get 'a' from upvalue
			Instruction(opcode: .getUpvalue, offset: 6, line: 4, metadata: .upvalue(slot: 0, name: "a")),
			// Do the addition
			Instruction(opcode: .add, offset: 8, line: 4, metadata: .simple),

			Instruction(opcode: .return, offset: 9, line: 5, metadata: .simple),
		]

		#expect(subchunk.disassemble() == subexpected)
	}
}
