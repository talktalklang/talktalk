//
//  UnknownSemanticNode.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct UnknownSemanticNode: SemanticNode {
	public var syntax: any Syntax
	public var scope: Scope
	public var type: any SemanticType = UnknownType()
}

public extension SemanticNode where Self == UnknownSemanticNode {
	static func unknown(syntax: any Syntax, scope: Scope) -> UnknownSemanticNode {
		UnknownSemanticNode(syntax: syntax, scope: scope)
	}
}
