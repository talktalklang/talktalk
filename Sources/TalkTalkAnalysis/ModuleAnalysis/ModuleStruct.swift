//
//  ModuleStruct.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import TalkTalkBytecode
import TalkTalkSyntax
import OrderedCollections

// Module structs are type level structs that can be shared across
// module boundaries.
public struct ModuleStruct: ModuleGlobal {
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
