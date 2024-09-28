//
//  ModuleFunction.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import TalkTalkBytecode
import TalkTalkCore

public struct ModuleFunction: ModuleGlobal {
	public let name: String
	public let symbol: Symbol
	public let location: SourceLocation
	public let typeID: InferenceType
	public var source: ModuleSource

	public var isImport: Bool {
		if case .module = source {
			return false
		}

		return true
	}
}
