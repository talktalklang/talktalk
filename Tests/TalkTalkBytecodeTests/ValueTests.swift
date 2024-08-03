//
//  ValueTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Testing
import TalkTalkBytecode

struct ValueTests {
	@Test("What are bits") func bits() {
		#expect(Value.int(0).bits == [
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
		])
	}

	@Test("Memory size") func memorySize() {
		#expect(MemoryLayout<Value>.size == 8)
	}

	@Test("Ints") func ints() {
		let value = Value.int(123)
		#expect(value.intValue == 123)
	}

	@Test("Bools") func bools() {
		#expect(Value.bool(true).boolValue == true)
		#expect(Value.bool(false).boolValue == false)
	}

	@Test("Data") func data() {
		#expect(Value.data(123).dataValue == 123)
	}
}
