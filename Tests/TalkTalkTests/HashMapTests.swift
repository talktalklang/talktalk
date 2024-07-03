//
//  HashMap.swift
//  
//
//  Created by Pat Nakajima on 7/2/24.
//
@testable import TalkTalk
import Testing

struct HashMapTests {
	@Test("Can be created") func create() {
		_ = HashMap()
	}

	@Test("Hasher") func hasher() {
		var hashera = Hasher()
		hashera.combine(1)
		hashera.combine(2)
		hashera.combine(3)

		var hasherb = Hasher()
		hasherb.combine(3)
		hasherb.combine(2)
		hasherb.combine(1)

		#expect(hashera.value != hasherb.value)
	}

	@Test("Set a value") func set() {
		let hashMap = HashMap()
		hashMap.set(.string("foo"), .number(123))
	}

	@Test("Get a value") func get() {
		let hashMap = HashMap()

		hashMap.set(.number(100), .number(123))

		#expect(hashMap.get(.number(100)) == .number(123))
		#expect(hashMap.get(.number(200)) == nil)
	}

	@Test("Collisions") func collisions() {
		Hasher.isBadAlgorithm = true

		let hashMap = HashMap()

		hashMap.set(.number(100), .string("one hundred"))
		hashMap.set(.number(200), .string("two hundred"))

		#expect(hashMap.get(.number(100)) == .string("one hundred"))
		#expect(hashMap.get(.number(200)) == .string("two hundred"))
	}
}
