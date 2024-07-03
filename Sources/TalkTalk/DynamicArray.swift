//
//  DynamicArray.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//
struct DynamicArray<T>: ~Copyable {
	var count = 0
	var capacity = 0
	var storage = UnsafeMutablePointer<T>.allocate(capacity: 0)

	subscript(_ index: Int) -> T {
		get {
			storage[index]
		}

		set {
			storage[index] = newValue
		}
	}

	// Adds the value to the storage, resizing if necessary. Returns the offset
	// of the written value.
	@discardableResult mutating func write(_ value: T) -> Int {
		if capacity < count + 1 {
			grow()
		}

		storage.advanced(by: count).pointee = value
		count += 1

		return count - 1
	}

	func read(byte: Byte) -> T {
		storage.advanced(by: Int(byte)).pointee
	}

	mutating func grow() {
		let newCapacity = capacity < 1 ? 1 : capacity * 2

		let newPointer = UnsafeMutablePointer<T>.allocate(capacity: newCapacity)
		newPointer.moveInitialize(from: storage, count: count)

		storage.deallocate()
		storage = newPointer
		capacity = newCapacity
	}

	deinit {
		storage.deallocate()
	}
}
