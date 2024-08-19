//
//  Variable.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode

public struct Variable: Equatable {
	var name: String
	var pointer: Pointer
	var depth: Int
	var isCaptured: Bool
	var getter: Opcode
	var setter: Opcode

	static func reserved(depth: Int) -> Variable {
		Variable(name: "__reserved__", pointer: .stack(0), depth: depth, isCaptured: false, getter: .getLocal, setter: .setLocal)
	}
}
