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
	public let type: ValueType
	public let source: ModuleSource

	public var isImport: Bool {
		if case .module = source {
			return false
		}

		return true
	}
}
