//
//  Stack.swift
//
//
//  Created by Pat Nakajima on 7/3/24.
//
import TalkTalkBytecode

struct Stack<Element> {
	private var storage: ContiguousArray<Element>

	init(capacity: Int) {
		self.storage = .init()
	}

	subscript(_ index: Int) -> Element {
		get {
			storage[index]
		}

		set {
			storage[index] = newValue
		}
	}

	var size: Int {
		storage.count
	}

	mutating func entries() -> ContiguousArray<Element> {
		storage
	}

	mutating func reset() {
		storage = []
	}

	@inline(__always)
	var isEmpty: Bool {
		storage.isEmpty
	}

	@inline(__always)
	mutating func push(_ element: Element) {
		storage.append(element)
	}

	@inline(__always)
	@discardableResult mutating func pop() -> Element {
		storage.popLast()!
	}

	@inline(__always)
	func peek(offset: Int = 0) -> Element {
		storage[size - 1 - offset]
	}

	@inline(__always)
	mutating func pop(count: Int) -> [Element] {
		(size - count ..< size).map { _ in pop() }
	}

	@inline(__always)
	func last(count: Int) -> [Element] {
		(0 ..< size).map { i in peek(offset: count - i) }
	}
}
