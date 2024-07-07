//
//  ValueTests.swift
//
//
//  Created by Pat Nakajima on 7/5/24.
//
@testable import TalkTalk
import Testing

struct ValueTests {
	@Test("Test number description") func number() {
		let value = Value.int(123)
		#expect(value.description == "123.0")
	}

	@Test("Test string description") func string() {
		let value = Value.string("sup")
		#expect(value.description == "sup")
	}
}
