//
//  Upvalue.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/3/24.
//

import TalkTalkBytecode

class Upvalue {
	var value: Value
	var next: Upvalue?

	init(value: Value) {
		self.value = value
	}
}
