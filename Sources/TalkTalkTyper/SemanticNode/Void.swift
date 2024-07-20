//
//  Void.swift
//  
//
//  Created by Pat Nakajima on 7/20/24.
//

import TalkTalkSyntax

public struct VoidNode: SemanticNode {
	public var syntax: any Syntax
	public var scope: Scope
	public var type: any SemanticType = .void
}

extension SemanticNode where Self == VoidNode {
	static func void(syntax: any Syntax, scope: Scope) -> VoidNode {
		VoidNode(syntax: syntax, scope: scope)
	}
}
