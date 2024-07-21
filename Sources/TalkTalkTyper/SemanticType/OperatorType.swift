//
//  OperatorType.swift
//  
//
//  Created by Pat Nakajima on 7/21/24.
//

import TalkTalkSyntax

public struct OperatorType: SemanticType {
	public var description = "Operator"

	public func assignable(from other: any SemanticType) -> Bool {
		other is OperatorType
	}
}

public extension SemanticType where Self == OperatorType {
	static var op: OperatorType { OperatorType() }
}
