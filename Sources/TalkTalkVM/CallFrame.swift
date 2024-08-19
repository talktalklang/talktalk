//
//  CallFrame.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/4/24.
//

import TalkTalkBytecode

public struct CallFrame: Equatable {
	public static func allocate(for chunk: Chunk, returnTo: UInt64, heap: Heap, arguments: [Value]) -> CallFrame {
		let heapValues = heap.allocate(count: Int(chunk.heapValueCount))

		var frame = CallFrame(chunk: chunk, returnTo: returnTo, heapPointers: heapValues)
		for (i, argument) in arguments.enumerated() {
			frame.locals[i+1] = argument
		}
		return frame
	}

	var ip: UInt64 = 0
	var chunk: Chunk
	var locals: [Value?]
	var heapPointers: [Heap.Pointer]
	var returnTo: UInt64

	private init(chunk: Chunk, returnTo: UInt64, heapPointers: [Heap.Pointer]) {
		self.chunk = chunk
		self.locals = Array(repeating: nil, count: Int(chunk.localsCount))
		self.returnTo = returnTo
		self.heapPointers = heapPointers
	}
}
