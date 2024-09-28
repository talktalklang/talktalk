//
//  ValueTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkBytecode
import Testing

@MainActor
struct ValueTests {
	@Test("opcodes can fit in a byte") func opcode() throws {
		#expect(Opcode.allCases.count < 255)
	}

	@Test("Memory size") func memorySize() {
		#expect(MemoryLayout<Value>.size <= 106)
	}
}
