//
//  Stack.swift
//
//
//  Created by Pat Nakajima on 7/3/24.
//
struct DebugStack<Element> {
	var storage: [Element] = []

	subscript(_ index: Int) -> Element {
		get {
			storage[index]
		}

		set {
			if storage.indices.contains(index) {
				storage[index] = newValue
			} else {
				print("!!!!!!!!!!!!!!! Invalid Stack Set Index: \(index) !!!!!!!!!!!!!!!!!!!!")
			}
		}
	}

	init(capacity _: Int) {
		self.storage = []
	}

	var size: Int {
		storage.count
	}

	mutating func entries() -> [Element] {
		storage
	}

	mutating func reset() {
		storage.removeAll()
	}

	var isEmpty: Bool {
		storage.isEmpty
	}

	mutating func push(_ element: Element) {
		storage.append(element)
	}

	@discardableResult mutating func pop() throws -> Element {
		guard let last = storage.popLast() else {
			throw VirtualMachineError.stackError("Cannot pop empty stack")
		}

		return last
	}

	func peek(offset _: Int = 0) throws -> Element {
		guard let last = storage.last else {
			throw VirtualMachineError.stackError("Cannot peek empty stack")
		}

		return last
	}

	mutating func pop(count: Int) throws -> [Element] {
		try (0 ..< count).map { _ in
			guard let last = storage.popLast() else {
				throw VirtualMachineError.stackError("Cannot pop \(count) from stack.")
			}

			return last
		}
	}
}

struct Stack<Element> {
	final class Storage: ManagedBuffer<Void, Element> {
		fileprivate func copy(count: Int) -> Storage {
			withUnsafeMutablePointers { _, elements in
				Storage.create(minimumCapacity: count) { newBuffer in
					newBuffer.withUnsafeMutablePointerToElements { newElements in
						newElements.initialize(from: elements, count: count)
					}
					// swiftlint:disable force_cast
				} as! Storage
				// swiftlint:disable force_cast
			}
		}

		fileprivate func resize(newSize: Int, oldSize: Int) -> Storage {
			withUnsafeMutablePointers { _, oldElements in
				Storage.create(minimumCapacity: newSize) { newBuf in
					newBuf.withUnsafeMutablePointerToElements { newElements in
						newElements.moveInitialize(from: oldElements, count: oldSize)
					}
					// swiftlint:disable force_cast
				} as! Storage
				// swiftlint:disable force_cast
			}
		}
	}

	public var capacity: Int
	private var storage: Storage
	public var size: Int = 0

	init(capacity: Int) {
		self.capacity = capacity
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

		return storage.withUnsafeMutablePointers { _, elements in
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
	mutating func push(_ element: Element) throws {
		if size == capacity {
			storage = storage.resize(newSize: capacity * 2, oldSize: capacity)
			capacity = capacity * 2
		}

		storage.withUnsafeMutablePointers {
			defer { size += 1 }
			($1 + size).initialize(to: element)
		}
	}

	@inline(__always)
	@discardableResult mutating func pop() throws -> Element {
		if size == 0 {
			throw VirtualMachineError.stackError("Cannot pop empty stack")
		}

		return storage.withUnsafeMutablePointers {
			size -= 1
			return ($1 + size).pointee
		}
	}

//	@inline(__always)
	func peek(offset: Int = 0) throws -> Element {
		if size - 1 - offset < 0 {
			throw VirtualMachineError.stackError("Cannot peek offset: \(offset)")
		}

		return storage.withUnsafeMutablePointers {
			($1 + size - 1 - offset).pointee
		}
	}

	@inline(__always)
	mutating func pop(count: Int) throws -> [Element] {
		try (size - count ..< size).map { _ in try pop() }
	}

	@inline(__always)
	mutating func drop(count: Int) throws {
		if count <= 0 { return }

		if count >= size {
			size = 0
			return
		}

		size -= count
	}

	@inline(__always)
	func last(count: Int) throws -> [Element] {
		try (0 ..< size).map { i in try peek(offset: count - i) }
	}
}
