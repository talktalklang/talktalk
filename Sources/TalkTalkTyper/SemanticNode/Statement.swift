//
//  Statement.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct SemanticStatement: SemanticNode {
	public var binding: Binding
	public let syntax: any Stmt
}
