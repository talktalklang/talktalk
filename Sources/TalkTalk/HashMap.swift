//
//  HashMap.swift
//
//
//  Created by Pat Nakajima on 7/2/24.
//

struct Hasher {
	nonisolated(unsafe) static var isBadAlgorithm = false

	var value: Int = 2_166_136_261

	mutating func combine(_ i: Int) {
		value ^= i
		value &*= 16_777_619
	}

	mutating func combine(_ char: Character) {
		if !Self.isBadAlgorithm {
			for i in char.unicodeScalars.map(\.value) {
				combine(Int(i))
			}
		}
	}
}

class HashMap {
	var storage: [Int: Value] = [:]

	public func set(_ key: Value, _ value: Value) {
		storage[key.hash] = value
	}

	public func get(_ key: Value) -> Value? {
		storage[key.hash]
	}
}
