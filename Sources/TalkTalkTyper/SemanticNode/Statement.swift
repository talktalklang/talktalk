//
//  Statement.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct SemanticStatement: SemanticNode {
	public var scope: Scope
	public let syntax: any Stmt
	public var type: any SemanticType = VoidType()
}
