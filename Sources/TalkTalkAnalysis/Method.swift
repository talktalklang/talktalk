//
//  Method.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/9/24.
//

import TalkTalkBytecode
import TalkTalkSyntax

public struct Method: Member {
	public let name: String
	public let slot: Int
	public let params: [InferenceType]
	public let inferenceType: InferenceType
	public let location: SourceLocation
	public let returnTypeID: InferenceType
	public let isMutable: Bool
	public let isSynthetic: Bool
	public var boundGenericParameters: [String: InferenceType] = [:]

	public init(
		name: String,
		slot: Int,
		params: [InferenceType],
		inferenceType: InferenceType,
		location: SourceLocation,
		returnTypeID: InferenceType,
		isMutable: Bool = false,
		isSynthetic: Bool = false
	) {
		self.name = name
		self.slot = slot
		self.params = params
		self.inferenceType = inferenceType
		self.location = location
		self.returnTypeID = returnTypeID
		self.isMutable = isMutable
		self.isSynthetic = isSynthetic
	}
}
