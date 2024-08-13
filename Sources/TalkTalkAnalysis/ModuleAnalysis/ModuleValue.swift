//
//  ModuleGlobal.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkSyntax
import TalkTalkBytecode

public struct SerializedModuleGlobal: Codable {
	enum GlobalType: Codable {
		case function, value
	}

	enum SerializedModuleSource: Codable {
		case module, external(String)
	}

	let name: String
	let type: TypeID
	let globalType: GlobalType
	let source: SerializedModuleSource
}

public struct ModuleValue: ModuleGlobal {
	public let name: String
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
