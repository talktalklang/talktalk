//
//  CallExpression.swift
//  
//
//  Created by Pat Nakajima on 7/23/24.
//
import TalkTalkSyntax

public struct CallExpression: Expression {
	public var scope: Scope
	public var syntax: any Syntax
	public var type: any SemanticType
	public var callee: any SemanticNode
	public var arguments: ArgumentList

	public func accept<V>(_ visitor: V) -> V.Value where V : ABTVisitor {
		visitor.visit(self)
	}
}
