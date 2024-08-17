//
//  BytecodeTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkBytecode
import Testing

@MainActor
struct BytecodeTests {
	@Test func basic() {
		#expect(Opcode.constant.rawValue == Byte(1))
	}
}
