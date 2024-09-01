//
//  Property.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkSyntax
import TypeChecker

public struct Property: Member {
	public let slot: Int
	public let name: String
	public let inferenceType: InferenceType
	public let location: SourceLocation
	public let isMutable: Bool
	public var boundGenericParameters: [String: InferenceType] = [:]
}
