//
//  Property.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode
import TalkTalkSyntax
import TypeChecker

public struct Property: Member {
	public let symbol: Symbol
	public let name: String
	public let inferenceType: InferenceType
	public let location: SourceLocation
	public let isMutable: Bool
	public let isStatic: Bool
}
