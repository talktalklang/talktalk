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
	var getter: Opcode
	var setter: Opcode

	static func reserved(depth: Int) -> Variable {
		Variable(
			name: "__reserved__",
			code: .symbol(StaticSymbol.value("__reserved__", "self")),
			depth: depth,
			getter: .getLocal,
			setter: .setLocal
		)
	}
}
