//
//  ModuleEnum.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/6/24.
//

import TalkTalkBytecode
import TalkTalkSyntax
import OrderedCollections

public struct ModuleEnum: ModuleGlobal {
	public let name: String
	public let symbol: Symbol
	public let location: SourceLocation
	public let typeID: InferenceType
	public var source: ModuleSource
	public var methods: OrderedDictionary<String, Method>

	public var isImport: Bool {
		if case .module = source {
			return false
		}

		return true
	}
}
