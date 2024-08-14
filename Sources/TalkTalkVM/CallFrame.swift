//
//  CallFrame.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/4/24.
//

import TalkTalkBytecode

class Closure {
	var chunk: Chunk
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

	// Store instances created in this call frame. This is sort of a weird attempt
	// to simulate lower level stuff that feels p leaky to me.
	// TODO: We're gonna need to figure out how they can move between frames?
	var instances: [StructInstance]

	// Store builtin instance separately because we call methods on them differently
	var builtinInstances: [any BuiltinStruct]
}
