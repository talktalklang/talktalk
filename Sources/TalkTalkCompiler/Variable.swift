//
//  Variable.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode

public struct Variable {
	var name: String
	var code: Code
	var depth: Int
	var isCaptured: Bool
	var getter: Opcode
	var setter: Opcode

	static func reserved(depth: Int) -> Variable {
		Variable(
			name: "__reserved__",
			code: .symbol(.value("__reserved__", "self")),
			depth: depth,
			isCaptured: false,
			getter: .getLocal,
			setter: .setLocal
		)
	}
}
