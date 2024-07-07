//
//  Stack.swift
//
//
//  Created by Pat Nakajima on 7/3/24.
//
struct Stack<Element> {
	class Storage: ManagedBuffer<Int, Element> {
		func copy() -> Storage {
			withUnsafeMutablePointers { header, elements in
				let count = header.pointee
				return Storage.create(minimumCapacity: count) { newBuffer in
					newBuffer.withUnsafeMutablePointerToElements { newElements in
						newElements.initialize(from: elements, count: count)
					}

					return header.pointee
				} as! Storage
			}
		}

		func resize(newSize: Int) -> Storage {
			withUnsafeMutablePointers { size, oldElements in
				let oldSize = size.pointee
				return Storage.create(minimumCapacity: newSize) { newBuf in
					newBuf.withUnsafeMutablePointerToElements { newElements in
						newElements.moveInitialize(from: oldElements, count: oldSize)
					}
					return oldSize
				} as! Storage
			}
		}
	}

	private var storage: Storage

	init(capacity: Int = 8) {
		self.storage = Storage.create(minimumCapacity: capacity) { _ in 0 } as! Storage
	}

	subscript(_ index: Int) -> Element {
		get {
			storage.withUnsafeMutablePointerToElements {
				$0[index]
			}
		}

		set {
			storage.withUnsafeMutablePointerToElements {
				$0[index] = newValue
			}
		}
	}

	mutating func entries() -> [Element] {
		let storage = isKnownUniquelyReferenced(&storage) ? storage : storage.copy()

		return storage.withUnsafeMutablePointers { header, elements in
			(0 ..< header.pointee).map { i in
				elements[i]
			}
		}
	}

	mutating func reset() {
		size = 0
	}

	var isEmpty: Bool {
		storage.header == 0
	}

	var size: Int {
		get {
			storage.withUnsafeMutablePointerToHeader { $0.pointee }
		}

		set {
			storage.withUnsafeMutablePointerToHeader { $0.pointee = newValue }
		}
	}

	mutating func push(_ element: Element) {
		if storage.capacity < storage.header + 1 {
			storage = storage.resize(newSize: storage.capacity * 2)
		}

		storage.withUnsafeMutablePointers {
			($1 + $0.pointee++).initialize(to: element)
		}
	}

	mutating func pop() -> Element {
		storage.withUnsafeMutablePointers {
			($1 + --$0.pointee).pointee
		}
	}

	func peek(offset: Int = 0) -> Element {
		storage.withUnsafeMutablePointers {
			($1 + $0.pointee - 1 - offset).pointee
		}
	}

	mutating func pop(count: Int) -> [Element] {
		(0 ..< count).map { _ in pop() }
	}

	func last(count: Int) -> [Element] {
		(0 ..< count).map { i in peek(offset: count - i) }
	}
}

//
//
// class Stack<Value> {
//	var size = 0
//	private var storage: ContiguousArray<Value> = []
//
//	subscript(_ offset: Int) -> Value {
//		get {
//			storage[offset]
//		}
//
//		set {
//			storage[offset] = newValue
//		}
//	}
//
//	subscript(_ range: Range<Int>) -> ArraySlice<Value> {
//		storage[range]
//	}
//
//	var isEmpty: Bool {
//		size == 0
//	}
//
//	var entries: some Collection<Value> {
//		storage
//	}
//
//	func peek(offset: Int = 0) -> Value {
//		return storage[size - 1 - offset]
//	}
//
//	func push(_ value: Value) {
//		storage.append(value)
//		size += 1
//	}
//
//	func pop() -> Value {
//		size -= 1
//		return storage.removeLast()
//	}
//
//	@discardableResult func pop(count: Int) -> [Value] {
//		defer {
//			size -= count
//		}
//
//		return (0 ..< count).map { _ in storage.removeLast() }
//	}
//
//	func last(count: Int) -> ArraySlice<Value> {
//		return storage[size - count..<size]
//	}
//
//	func reset() {
//		size = 0
//		storage = []
//	}
// }
