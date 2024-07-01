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

	// Adds the value to the storage, resizing if necessary. Returns the offset
	// of the written value.
	@discardableResult mutating func write(_ value: T) -> Int {
		if capacity < count + 1 {
			grow()
		}

		(storage + count).pointee = value
		count += 1

		return count - 1
	}

	mutating func grow() {
		let newCapacity = capacity < 8 ? 8 : capacity * 2
		let newPointer = UnsafeMutablePointer<T>.allocate(capacity: newCapacity)

		newPointer.initialize(from: storage, count: count)
		storage.deallocate()
		storage = newPointer
		capacity = newCapacity
	}

	deinit {
		storage.deallocate()
	}
}
