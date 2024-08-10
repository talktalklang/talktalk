//
//  ValueTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Testing
import TalkTalkBytecode

@MainActor
struct ValueTests {
	@Test("Memory size") func memorySize() {
		#expect(MemoryLayout<Value>.size < 16)
	}
}
