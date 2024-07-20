//
//  BoundSyntax.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct BoundSyntax<Node: Syntax> {
	public let node: Node
	public let binding: Scope
}
