//
//  Heap.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

// A fake heap
public final class Heap {
	// A fake pointer
	public final class Pointer: Hashable, Equatable, Codable, Sendable {
		public static func == (lhs: Pointer, rhs: Pointer) -> Bool {
			lhs.base == rhs.base && lhs.offset == rhs.offset
		}

		public static func + (lhs: Pointer, rhs: Int) -> Pointer {
			Pointer(base: lhs.base, offset: lhs.offset + rhs)
		}

		public let base: Int
		public let offset: Int

		public init(base: Int, offset: Int) {
			self.base = base
			self.offset = offset
		}

		public func hash(into hasher: inout Hasher) {
			hasher.combine(base)
			hasher.combine(offset)
		}

		public var description: String {
			"pointer(\(base), \(offset))"
		}
	}

	// A fake memory block
	class Block {
		let address: Int
		let capacity: Int
		var storage: ContiguousArray<Value?>

		init(address: Int, capacity: Int) {
			self.address = address
			self.capacity = capacity
			self.storage = ContiguousArray<Value?>(repeating: nil, count: capacity)
		}
	}

	private var storage: ContiguousArray<Block> = .init()

	public init() {}

	public func allocate(count: Int) -> Pointer {
		let current = storage.count
		let block = Heap.Block(address: current, capacity: .init(count))
		storage.append(block)
		return Pointer(base: current, offset: 0)
	}

	public func size(of block: Int) -> Int {
		storage[block].capacity
	}

	public func copy(pointer: Pointer, length: Int, into: inout [Value?]) {
		into = Array(storage[pointer.base].storage[0 ..< length])
	}

	public func dereference(pointer: Pointer) -> Value? {
		storage[pointer.base].storage[pointer.offset]
	}

	public func store(pointer: Pointer, value: Value) {
		storage[pointer.base].storage[pointer.offset] = value
	}

	public func free(pointer: Pointer) {
		storage.remove(at: pointer.base)
	}
}
