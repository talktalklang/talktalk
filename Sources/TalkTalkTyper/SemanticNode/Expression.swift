//
//  Expression.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct Expression<Node: Expr>: SemanticNode {
	public let syntax: Node
	public let value: Value
	public var binding: Binding
}
