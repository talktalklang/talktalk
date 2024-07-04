//
//  DynamicArray.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//
struct DynamicArray<T> {
	var capacity = 0
	var storage: [T] = []

	subscript(_ index: Int) -> T {
		get {
			storage[index]
		}

		set {
			storage[index] = newValue
		}
	}

	var count: Int {
		storage.count
	}

	// Adds the value to the storage, resizing if necessary. Returns the offset
	// of the written value.
	@discardableResult mutating func write(_ value: T) -> Int {
		storage.append(value)
		return storage.count - 1
	}

	func read(byte: Byte) -> T {
		storage[Int(byte)]
	}
}
