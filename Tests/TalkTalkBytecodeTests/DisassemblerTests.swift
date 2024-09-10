//
//  DisassemblerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkBytecode
import Testing

@MainActor
struct DisassemblerTests {
	@Test("Disassembles simple opcodes") func simple() throws {
		let chunk = Chunk(name: "main", symbol: .function("DisassemblerTests", "main", []), path: "test")
		chunk.emit(opcode: .true, line: 1)

		#expect(chunk.code == [.opcode(.true)])

		try #expect(chunk.disassemble() == [
			Instruction(path: chunk.path, opcode: .true, offset: 1, line: 1, metadata: .simple),
		])
	}

	@Test("Disassembles constant opcodes") func constant() throws {
		let chunk = Chunk(name: "main", symbol: .function("DisassemblerTests", "main", []), path: "test")
		chunk.emit(constant: .int(123), line: 1)
		chunk.emit(opcode: .returnVoid, line: 2)

		try #expect(chunk.disassemble() == [
			Instruction(path: chunk.path, opcode: .constant, offset: 1, line: 1, metadata: ConstantMetadata(value: .int(123))),
			Instruction(path: chunk.path, opcode: .returnVoid, offset: 3, line: 2, metadata: .simple),
		])
	}
}
