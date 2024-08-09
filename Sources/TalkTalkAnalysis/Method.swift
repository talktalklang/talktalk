//
//  Method.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/9/24.
//

import TalkTalkSyntax

public struct SerializedMethod: Codable {
	public let slot: Int
	public let name: String
	public let params: [String]
	public let type: ValueType
	public let isMutable: Bool
}

public struct Method: Member {
	public let slot: Int
	public let name: String
	public let params: [String]
	public let type: ValueType
	public let expr: any Syntax
	public let isMutable: Bool
}
