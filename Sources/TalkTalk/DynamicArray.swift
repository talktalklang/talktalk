//
//  DynamicArray.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//
typealias DynamicArray = ContiguousArray
extension DynamicArray {
	// Adds the value to the storage, resizing if necessary. Returns the offset
	// of the written value.
	@discardableResult mutating func write(_ value: Element) -> Int {
		append(value)
		return count - 1
	}

	func read(byte: Byte) -> Element {
		self[Int(byte)]
	}
}
