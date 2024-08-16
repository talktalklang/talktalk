//
//  ModuleGlobal.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkSyntax
import TalkTalkBytecode



public struct ModuleValue: ModuleGlobal {
	public let name: String
	public let syntax: any Syntax
	public let typeID: TypeID
	public var source: ModuleSource
	public var isMutable: Bool

	public var isImport: Bool {
		if case .module = source {
			return false
		}

		return true
	}
}
