//
//  VarExpression.swift
//  
//
//  Created by Pat Nakajima on 7/23/24.
//

import TalkTalkSyntax

public struct VarExpression: SemanticNode, Expression {
	public var scope: Scope
	public var syntax: any Syntax
	public var type: any SemanticType
	public var name: String

	public func accept<V>(_ visitor: V) -> V.Value where V : ABTVisitor {
		visitor.visit(self)
	}
}
