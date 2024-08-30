//
//  Method.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/9/24.
//

import TalkTalkBytecode
import TalkTalkSyntax

public struct Method: Member {
	public let symbol: Symbol
	public let name: String
	public let slot: Int
	public let params: [AnalyzedParam]
	public let inferenceType: InferenceType
	public let returnTypeID: InferenceType
	public let expr: any Syntax
	public let isMutable: Bool
	public let isSynthetic: Bool
	public var boundGenericParameters: [String: InferenceType] = [:]

	public init(
		symbol: Symbol,
		name: String,
		slot: Int,
		params: [AnalyzedParam],
		inferenceType: InferenceType,
		returnTypeID: InferenceType,
		expr: any Syntax,
		isMutable: Bool = false,
		isSynthetic: Bool = false
	) {
		self.symbol = symbol
		self.name = name
		self.slot = slot
		self.params = params
		self.inferenceType = inferenceType
		self.returnTypeID = returnTypeID
		self.expr = expr
		self.isMutable = isMutable
		self.isSynthetic = isSynthetic
	}
}
