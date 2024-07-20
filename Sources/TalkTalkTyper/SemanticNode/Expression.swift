//
//  Expression.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct Expression: SemanticNode {
	public var type: any SemanticType
	public let syntax: any Expr
	public let value: Value
	public var binding: Binding
}
