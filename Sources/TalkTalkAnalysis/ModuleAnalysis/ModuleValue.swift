//
//  ModuleValue.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode
import TalkTalkSyntax

public struct ModuleValue: ModuleGlobal {
	public let name: String
	public let symbol: Symbol
	public let syntax: any Syntax
	public let typeID: InferenceType
	public var source: ModuleSource
	public var isMutable: Bool

	public var isImport: Bool {
		if case .module = source {
			return false
		}

		return true
	}
}
