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

	func free(address: Int) {
		storage.remove(at: address)
	}
}
