//
//  AssignmentExpression.swift
//
//
//  Created by Pat Nakajima on 7/23/24.
//
import TalkTalkSyntax

public struct AssignmentExpression: SemanticNode {
	public var scope: Scope
	public var syntax: any TalkTalkSyntax.Syntax
	public var type: any SemanticType
	public var lhs: any SemanticNode
	public var rhs: any SemanticNode

	public func accept<V>(_ visitor: V) -> V.Value where V : ABTVisitor {
		visitor.visit(self)
	}
}
