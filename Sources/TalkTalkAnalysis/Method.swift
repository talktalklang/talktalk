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
	public let symbol: Symbol
	public let params: [InferenceType]
	public let inferenceType: InferenceType
	public let location: SourceLocation
	public let returnTypeID: InferenceType
	public let isMutable: Bool
	public let isSynthetic: Bool
	public let isStatic: Bool
	public var boundGenericParameters: [String: InferenceType] = [:]

	public init(
		name: String,
		symbol: Symbol,
		params: [InferenceType],
		inferenceType: InferenceType,
		location: SourceLocation,
		returnTypeID: InferenceType,
		isMutable: Bool = false,
		isSynthetic: Bool = false,
		isStatic: Bool = false
	) {
		self.name = name
		self.symbol = symbol
		self.params = params
		self.inferenceType = inferenceType
		self.location = location
		self.returnTypeID = returnTypeID
		self.isMutable = isMutable
		self.isSynthetic = isSynthetic
		self.isStatic = isStatic
	}
}
