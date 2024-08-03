//
//  ChunkTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Testing
import TalkTalkBytecode

struct ChunkTests {
	@Test("Opcode") func opcode() {
		let chunk = Chunk()
		chunk.emit(opcode: .true, line: 1)

		#expect(chunk.code == [
			Opcode.true.rawValue,
		])
	}

	@Test("Emit constant") func emitConstant() {
		let chunk = Chunk()
		chunk.emit(constant: .int(123), line: 1)

		#expect(chunk.code == [
			Opcode.constant.rawValue,
			0,
		])

		#expect(chunk.constants == [
			.int(123)
		])
	}
}