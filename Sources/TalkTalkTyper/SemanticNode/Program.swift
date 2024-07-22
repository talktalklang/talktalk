//
//  Program.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct Program: SemanticNode {
	public var syntax: any Syntax
	public var scope: Scope
	public var declarations: [any SemanticNode]
	public var type: any SemanticType = VoidType()

	public func accept<V: ABTVisitor>(_ visitor: V) -> V.Value {
		visitor.visit(self)
	}
}
