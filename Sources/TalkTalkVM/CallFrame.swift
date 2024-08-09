//
//  CallFrame.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/4/24.
//

import TalkTalkBytecode

class Closure {
	let chunk: Chunk
	let upvalues: [Upvalue]

	public init(chunk: Chunk, upvalues: [Upvalue]) {
		self.chunk = chunk
		self.upvalues = upvalues
	}
}

public struct CallFrame {
	var ip: UInt64 = 0
	var closure: Closure
	var returnTo: UInt64
	var stackOffset: Int

	// Store instances created in this call frame
	// TODO: We're gonna need to figure out how they can move between frames?
	var instances: [StructInstance] = []
}
