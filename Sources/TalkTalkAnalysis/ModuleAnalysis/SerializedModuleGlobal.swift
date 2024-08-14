//
//  SerializedModuleGlobal.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

public struct SerializedModuleGlobal: Codable {
	enum GlobalType: Codable {
		case function, value
	}

	enum SerializedModuleSource: Codable {
		case module, external(String)
	}

	let name: String
	let type: ValueType
	let globalType: GlobalType
	let source: SerializedModuleSource
}
