//
//  Heap.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkBytecode

// A fake heap
public class Heap {
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

	func allocate(count: Int) -> Int {
		let current = storage.count
		let block = Heap.Block(address: current, capacity: .init(count))
		storage.append(block)
		return current
	}

	func size(of block: Int) -> Int {
		storage[block].capacity
	}

	func copy(base: Int, length: Int, into: inout [Value?]) {
		into = Array(storage[base].storage[0 ..< length])
	}

	func dereference(block: Int, offset: Int) -> Value? {
		storage[block].storage[offset]
	}

	func store(block: Int, offset: Int, value: Value) {
		storage[block].storage[offset] = value
	}

	func free(address: Int) {
		storage.remove(at: address)
	}
}
