//
//  ModuleProtocol.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/20/24.
//

import OrderedCollections
import TalkTalkBytecode
import TalkTalkCore

public struct ModuleProtocol: ModuleGlobal {
	public let id: SyntaxID
	public var name: String
	public var symbol: Symbol
	public var location: SourceLocation
	public var typeID: InferenceType
	public var source: ModuleSource

	public var properties: OrderedDictionary<String, Property>
	public var methods: OrderedDictionary<String, Method>
	public var typeParameters: [TypeParameter]

	public var isImport: Bool {
		if case .module = source {
			return false
		}

		return true
	}
}
