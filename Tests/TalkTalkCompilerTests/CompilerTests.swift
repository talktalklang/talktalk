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
			Instruction(opcode: .constant, line: 1, offset: 0, metadata: ConstantMetadata(value: 123)),
			Instruction(opcode: .return, line: 0, offset: 2, metadata: .simple)
		]

		#expect(chunk.disassemble() == instructions)
	}

	@Test("Binary int op") func binaryIntOp() {
		let chunk = compile("10 + 20")

		let instructions = [
			Instruction(opcode: .constant, line: 1, offset: 0, metadata: ConstantMetadata(value: 20)),
			Instruction(opcode: .constant, line: 1, offset: 2, metadata: ConstantMetadata(value: 10)),
			Instruction(opcode: .add, line: 1, offset: 4, metadata: .simple),
			Instruction(opcode: .return, line: 0, offset: 5, metadata: .simple)
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
			Instruction(opcode: .constant, line: 1, offset: 0, metadata: ConstantMetadata(value: .data(0))),
			Instruction(opcode: .constant, line: 2, offset: 2, metadata: ConstantMetadata(value: .data(8))),
			Instruction(opcode: .return, line: 0, offset: 4, metadata: .simple)
		]

		print(result.map(\.description).joined(separator: "\n"))
		print("----")
		print(expected.map(\.description).joined(separator: "\n"))

		#expect(result == expected)
	}
}
