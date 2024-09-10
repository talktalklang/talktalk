//
//  EnumMember.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/6/24.
//

import TypeChecker
import TalkTalkBytecode
import TalkTalkSyntax

public struct EnumMember: Member {
	public var name: String
	public var ownerSlot: Int
	public var symbol: Symbol
	public var inferenceType: InferenceType
	public var location: SourceLocation
	public var isMutable: Bool
}