//
//  BinaryOpExpression.swift
//  
//
//  Created by Pat Nakajima on 7/21/24.
//

import TalkTalkSyntax

public struct BinaryOpExpression: SemanticNode {
	public var scope: Scope
	public var syntax: any Syntax
	public var type: any SemanticType = .binaryOperation

	public var lhs: any Expression
	public var rhs: any Expression
	public var op: OperatorNode
}
