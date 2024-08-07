//
//  ModuleGlobal.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkSyntax
import TalkTalkBytecode

public struct ModuleGlobal {
	let name: String
	let syntax: any Syntax
	public let type: ValueType
}
