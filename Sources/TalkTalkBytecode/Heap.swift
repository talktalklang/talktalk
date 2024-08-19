//
//  Heap.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

// A fake heap
public class Heap {
	public struct Pointer: Codable, Sendable, Hashable, Equatable {
		public static func +(lhs: Pointer, rhs: Value.IntValue) -> Pointer {
			Pointer(blockID: lhs.blockID, offset: lhs.offset + Int(rhs))
		}

		let blockID: Int
		let offset: Int
	}

	// A fake memory block
	public class Block: Equatable {
		public static func ==(lhs: Block, rhs: Block) -> Bool {
			lhs.address == rhs.address && lhs.storage == rhs.storage
		}

		let address: Int
		let capacity: Int
		var storage: ContiguousArray<Value?>

		init(address: Int, capacity: Int) {
			self.address = address
			self.capacity = capacity
			self.storage = ContiguousArray<Value?>(repeating: nil, count: capacity)
		}

		subscript(_ index: Int) -> Value? {
			get {
				storage[index]
			}

			set {
				storage[index] = newValue
			}
		}
	}

	private var storage: ContiguousArray<Block> = .init()

	public init() {
		self.storage = ContiguousArray<Block>()
	}

	public func allocate(count: Int) -> Pointer {
		let current = storage.count
		let block = Heap.Block(address: current, capacity: .init(count))
		storage.append(block)
		return Pointer(blockID: current, offset: 0)
	}

	public func size(of block: Int) -> Int {
		storage[block].capacity
	}

	public func copy(base: Int, length: Int, into: inout [Value?]) {
		into = Array(storage[base].storage[0 ..< length])
	}

	public func dereference(pointer: Heap.Pointer) -> Value? {
		storage[pointer.blockID].storage[pointer.offset]
	}

	public func store(pointer: Heap.Pointer, value: Value) {
		storage[pointer.blockID].storage[pointer.offset] = value
	}

	public func free(address: Int) {
		storage.remove(at: address)
	}
}
