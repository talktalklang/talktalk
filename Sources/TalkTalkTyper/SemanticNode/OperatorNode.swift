//
//  OperatorNode.swift
//  
//
//  Created by Pat Nakajima on 7/21/24.
//

import TalkTalkSyntax

public struct OperatorNode: SemanticNode, Expression {
	public var syntax: any Syntax
	public var scope: Scope
	public var type: any SemanticType = OperatorType()
	public var allowedOperandTypes: [any SemanticType]

	public func accept<V: ABTVisitor>(_ visitor: V) -> V.Value {
		visitor.visit(self)
	}
}
