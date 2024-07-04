//
//  Stack.swift
//
//
//  Created by Pat Nakajima on 7/3/24.
//

class Stack<Value> {
	var size = 0
	private var storage: [Value] = []

	subscript(_ offset: Int) -> Value {
		get {
			storage[offset]
		}

		set {
			storage[offset] = newValue
		}
	}

	var isEmpty: Bool {
		size == 0
	}

	func peek(offset: Int = 0) -> Value {
		storage[size - 1 - offset]
	}

	func push(_ value: Value) {
		storage.append(value)
		size += 1
	}

	func pop() -> Value {
		size -= 1
		return storage.removeLast()
	}

	func reset() {
		size = 0
		storage = []
	}
}
