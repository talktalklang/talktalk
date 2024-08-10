//
//  ModuleFunction.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import TalkTalkSyntax
import TalkTalkBytecode

public struct ModuleFunction: ModuleGlobal {
	public let name: String
	public let syntax: any Syntax
	public let type: ValueType
	public var source: ModuleSource

	public var isImport: Bool {
		if case .module = source {
			return false
		}

		return true
	}
}
