//
//  ArgumentList.swift
//  
//
//  Created by Pat Nakajima on 7/23/24.
//

import TalkTalkSyntax

public struct ArgumentList: SemanticNode {
	public var scope: Scope
	public var syntax: any Syntax
	public var type: any SemanticType = .void
	public var list: [(name: String, node: any SemanticNode)]

	public func accept<V>(_ visitor: V) -> V.Value where V : ABTVisitor {
		visitor.visit(self)
	}
}
