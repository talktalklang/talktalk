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
		#expect(Value(0).bits == [
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
		])
	}

	@Test("Ints") func ints() {
		let value = Value.int(123)
		#expect(value.result == .int(123))
	}

	@Test("Bools") func bools() {
		#expect(Value.bool(true) == .bool(true))
		#expect(Value.bool(false) == .bool(false))
	}

	@Test("Data") func data() {
		#expect(Value.data(123).asData == 123)
	}
}
