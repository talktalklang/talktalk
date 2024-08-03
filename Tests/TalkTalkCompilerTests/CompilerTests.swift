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
	func compile(_ string: String) -> StaticChunk {
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
			Instruction(opcode: .constant, line: 1, offset: 0, metadata: ConstantMetadata(value: .int(123))),
			Instruction(opcode: .return, line: 0, offset: 2, metadata: .simple)
		]

		#expect(chunk.disassemble() == instructions)
	}

	@Test("Binary int op") func binaryIntOp() {
		let chunk = compile("10 + 20")

		let instructions = [
			Instruction(opcode: .constant, line: 1, offset: 0, metadata: ConstantMetadata(value: .int(20))),
			Instruction(opcode: .constant, line: 1, offset: 2, metadata: ConstantMetadata(value: .int(10))),
			Instruction(opcode: .add, line: 1, offset: 4, metadata: .simple),
			Instruction(opcode: .return, line: 0, offset: 5, metadata: .simple)
		]

		#expect(chunk.disassemble() == instructions)
	}

	@Test("Static string") func staticString() {
		let chunk = Chunk(staticChunk: compile("""
		"hello "
		"world"
		"""))

		var string1 = "hello ".utf8CString
		let pointer1 = string1.withUnsafeMutableBufferPointer { $0 }

		var string2 = "world".utf8CString
		let pointer2 = string2.withUnsafeMutableBufferPointer { $0 }

		chunk.data = Object.string(pointer1).bytes + Object.string(pointer2).bytes

		let result = chunk.disassemble()
		let expected = [
			Instruction(opcode: .constant, line: 1, offset: 0, metadata: ConstantMetadata(value: .data(0))),
			Instruction(opcode: .constant, line: 2, offset: 2, metadata: ConstantMetadata(value: .data(8))),
			Instruction(opcode: .return, line: 0, offset: 4, metadata: .simple)
		]

		#expect(result == expected)
	}

	@Test("Def expr") func defExpr() {
		let chunk = compile("""
		i = 123
		""")

		#expect(chunk.disassemble() == [
			Instruction(opcode: .constant, line: 1, offset: 0, metadata: .constant(.int(123))),
			Instruction(opcode: .setLocal, line: 1, offset: 2, metadata: .local(slot: 0)),
			Instruction(opcode: .return, line: 0, offset: 4, metadata: .simple)
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
			Instruction(opcode: .constant, line: 1, offset: 0, metadata: .constant(.int(123))),
			Instruction(opcode: .setLocal, line: 1, offset: 2, metadata: .local(slot: 0)),
			Instruction(opcode: .getLocal, line: 2, offset: 4, metadata: .local(slot: 0)),
			Instruction(opcode: .constant, line: 3, offset: 6, metadata: .constant(.int(456))),
			Instruction(opcode: .setLocal, line: 3, offset: 8, metadata: .local(slot: 1)),
			Instruction(opcode: .getLocal, line: 4, offset: 10, metadata: .local(slot: 1)),
			Instruction(opcode: .return, line: 0, offset: 12, metadata: .simple)
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
			Instruction(opcode: .false, line: 1, offset: 0, metadata: .simple),
			// How far to jump if the condition is false
			Instruction(opcode: .jumpUnless, line: 1, offset: 1, metadata: .jump(offset: 6)),
			// Pop the condition
			Instruction(opcode: .pop, line: 1, offset: 4, metadata: .simple),

			// If we're not jumping, here's the value of the consequence block
			Instruction(opcode: .constant, line: 2, offset: 7, metadata: .constant(.int(123))),
			// If the condition was true, we want to jump over the alernative block
			Instruction(opcode: .jump, line: 3, offset: 10, metadata: .jump(offset: 3)),
			// Pop the condition
			Instruction(opcode: .pop, line: 1, offset: 10, metadata: .simple),

			// If the condition was false, we jumped here
			Instruction(opcode: .constant, line: 4, offset: 7, metadata: .constant(.int(456))),

			// return the result
			Instruction(opcode: .return, line: 0, offset: 5, metadata: .simple)
		])
	}
}
