//
//  BinaryOpExpression.swift
//  
//
//  Created by Pat Nakajima on 7/21/24.
//

import TalkTalkSyntax

public struct BinaryOpType: SemanticType {
	public var description = "BinaryOpType"

	public func assignable(from other: any SemanticType) -> Bool {
		other is BinaryOpType
	}
}

public extension SemanticType where Self == BinaryOpType {
	static var binaryOperation: BinaryOpType { BinaryOpType() }
}
