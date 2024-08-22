//
//  ModuleStruct.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import TalkTalkBytecode
import TalkTalkSyntax

// Module structs are type level structs that can be shared across
// module boundaries.
public struct ModuleStruct: ModuleGlobal {
	public var name: String
	public var symbol: Symbol
	public var syntax: any Syntax
	public var typeID: TypeID
	public var source: ModuleSource

	public var properties: [String: Property]
	public var methods: [String: Method]
	public var typeParameters: [TypeParameter]

	public var isImport: Bool {
		if case .module = source {
			return false
		}

		return true
	}
}
