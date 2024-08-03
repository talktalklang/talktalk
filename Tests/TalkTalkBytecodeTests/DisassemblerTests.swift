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
		let chunk = Chunk()
		chunk.emit(opcode: .true, line: 1)

		#expect(chunk.disassemble() == [
			Instruction(opcode: .true, line: 1, offset: 1, metadata: .simple)
		])
	}

	@Test("Disassembles constant opcodes") func constant() {
		let chunk = Chunk()
		chunk.emit(constant: 123, line: 1)
		chunk.emit(opcode: .return, line: 2)

		#expect(chunk.disassemble() == [
			Instruction(opcode: .constant, line: 1, offset: 1, metadata: ConstantMetadata(value: 123)),
			Instruction(opcode: .return, line: 2, offset: 3, metadata: .simple)
		])
	}
}
