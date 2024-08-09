//
//  StructInstance.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import TalkTalkBytecode

struct StructInstance {
	let type: Value
	var fields: [Value?]

	init(type: Value, fieldCount: Int) {
		self.type = type
		self.fields = Array(repeating: nil, count: fieldCount)
	}
}
