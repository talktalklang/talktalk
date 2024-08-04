//
//  DisassemblerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Testing
import TalkTalkBytecode

struct DisassemblerTests {
	@Test("Disassembles simple opcodes") func simple() {
		let chunk = Chunk(name: "main")
		chunk.emit(opcode: .true, line: 1)

		#expect(chunk.disassemble() == [
			Instruction(opcode: .true, offset: 1, line: 1, metadata: .simple)
		])
	}

	@Test("Disassembles constant opcodes") func constant() {
		let chunk = Chunk(name: "main")
		chunk.emit(constant: .int(123), line: 1)
		chunk.emit(opcode: .return, line: 2)

		#expect(chunk.disassemble() == [
			Instruction(opcode: .constant, offset: 1, line: 1, metadata: ConstantMetadata(value: .int(123))),
			Instruction(opcode: .return, offset: 3, line: 2, metadata: .simple)
		])
	}
}
