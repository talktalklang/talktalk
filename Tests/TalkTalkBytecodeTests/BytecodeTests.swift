//
//  BytecodeTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Testing
import TalkTalkBytecode

@MainActor
struct BytecodeTests {
	@Test func basic() {
		#expect(Opcode.constant.rawValue == Byte(1))
	}
}
