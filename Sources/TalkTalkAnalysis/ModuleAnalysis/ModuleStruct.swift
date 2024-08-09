//
//  ModuleStruct.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import TalkTalkSyntax

public struct ModuleStruct: ModuleGlobal {
	public var name: String
	public var syntax: any Syntax
	public var type: ValueType
	public var source: ModuleSource

	public var properties: [String: Property]
	public var methods: [String: Property]
}
