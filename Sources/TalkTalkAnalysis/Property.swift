//
//  Property.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkSyntax

public struct SerializedProperty: Codable {
	public let slot: Int
	public let name: String
	public let type: ValueType
	public let isMutable: Bool
}

public struct Property: Member {
	public let slot: Int
	public let name: String
	public let type: ValueType
	public let expr: any Syntax
	public let isMutable: Bool
}