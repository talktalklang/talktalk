//
//  Upvalue.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/3/24.
//

import TalkTalkBytecode

class Upvalue {
	enum State {
		case open(owner: CallFrame, slot: Byte), closed(Value)
	}

	var state: State
	var next: Upvalue?

	init(state: State) {
		self.state = state
	}
}
