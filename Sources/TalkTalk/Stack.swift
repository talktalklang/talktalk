//
//  Stack.swift
//
//
//  Created by Pat Nakajima on 7/3/24.
//
struct Stack<Element> {
	final class Storage: ManagedBuffer<Void, Element> {
		fileprivate func copy(count: Int) -> Storage {
			withUnsafeMutablePointers { header, elements in
				return Storage.create(minimumCapacity: count) { newBuffer in
					newBuffer.withUnsafeMutablePointerToElements { newElements in
						newElements.initialize(from: elements, count: count)
					}
				} as! Storage
			}
		}

		fileprivate func resize(newSize: Int, oldSize: Int) -> Storage {
			withUnsafeMutablePointers { size, oldElements in
				return Storage.create(minimumCapacity: newSize) { newBuf in
					newBuf.withUnsafeMutablePointerToElements { newElements in
						newElements.moveInitialize(from: oldElements, count: oldSize)
					}
				} as! Storage
			}
		}
	}

	private var storage: Storage
	public var size: Int = 0

	init(capacity: Int) {
		self.storage = Storage.create(minimumCapacity: capacity) { _ in } as! Storage
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
		let storage = isKnownUniquelyReferenced(&storage) ? storage : storage.copy(count: size)

		return storage.withUnsafeMutablePointers { header, elements in
			(0 ..< size).map { i in
				elements[i]
			}
		}
	}

	mutating func reset() {
		size = 0
	}

	@inline(__always)
	var isEmpty: Bool {
		size == 0
	}

	@inline(__always)
	mutating func push(_ element: Element) {
//		if storage.capacity < size + 1 {
//			storage = storage.resize(newSize: storage.capacity * 2, oldSize: size)
//		}

		storage.withUnsafeMutablePointers {
			($1 + size++).initialize(to: element)
		}
	}

	@inline(__always)
	mutating func pop() -> Element {
		storage.withUnsafeMutablePointers {
			($1 + --size).pointee
		}
	}

	@inline(__always)
	func peek(offset: Int = 0) -> Element {
		storage.withUnsafeMutablePointers {
			($1 + size - 1 - offset).pointee
		}
	}

	@inline(__always)
	mutating func pop(count: Int) -> [Element] {
		(0 ..< size).map { _ in pop() }
	}

	@inline(__always)
	func last(count: Int) -> [Element] {
		(0 ..< size).map { i in peek(offset: count - i) }
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
