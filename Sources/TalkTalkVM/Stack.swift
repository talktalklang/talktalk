//
//  Stack.swift
//
//
//  Created by Pat Nakajima on 7/3/24.
//
struct Stack<Element> {
	final class Storage: ManagedBuffer<Void, Element> {
		fileprivate func copy(count: Int) -> Storage {
			withUnsafeMutablePointers { _, elements in
				Storage.create(minimumCapacity: count) { newBuffer in
					newBuffer.withUnsafeMutablePointerToElements { newElements in
						newElements.initialize(from: elements, count: count)
					}
				} as! Storage
			}
		}

		fileprivate func resize(newSize: Int, oldSize: Int) -> Storage {
			withUnsafeMutablePointers { _, oldElements in
				Storage.create(minimumCapacity: newSize) { newBuf in
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
	mutating func push(_ element: Element) {
		storage.withUnsafeMutablePointers {
			defer { size += 1 }
			($1 + size).initialize(to: element)
		}
	}

	@inline(__always)
	@discardableResult mutating func pop() -> Element {
		storage.withUnsafeMutablePointers {
			size -= 1
			return ($1 + size).pointee
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
		(size - count ..< size).map { _ in pop() }
	}

	@inline(__always)
	func last(count: Int) -> [Element] {
		(0 ..< size).map { i in peek(offset: count - i) }
	}
}
