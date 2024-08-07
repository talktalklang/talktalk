//
//  BytecodeTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Testing
import TalkTalkBytecode

actor BytecodeTests {
	@Test func basic() {
		#expect(Opcode.constant.rawValue == Byte(1))
	}
}
