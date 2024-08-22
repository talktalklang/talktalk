//
//  ModuleFunction.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import TalkTalkBytecode
import TalkTalkSyntax

public struct ModuleFunction: ModuleGlobal {
	public let name: String
	public let symbol: Symbol
	public let syntax: any Syntax
	public let typeID: TypeID
	public var source: ModuleSource

	public var isImport: Bool {
		if case .module = source {
			return false
		}

		return true
	}
}
