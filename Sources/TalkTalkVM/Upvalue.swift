//
//  Upvalue.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/3/24.
//

import TalkTalkBytecode

class Upvalue {
	var depth: Byte
	var slot: Byte
	var next: Upvalue?

	init(depth: Byte, slot: Byte) {
		self.depth = depth
		self.slot = slot
	}
}
