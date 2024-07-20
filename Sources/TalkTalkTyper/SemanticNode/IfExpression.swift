//
//  IfExpression.swift
//  
//
//  Created by Pat Nakajima on 7/20/24.
//

import TalkTalkSyntax

public struct IfExpression: Expression {
	public var syntax: any Syntax
	public var scope: Scope
	public var type: any SemanticType

	public var condition: any SemanticNode
	public var consequence: any SemanticNode
	public var alternative: any SemanticNode
}
