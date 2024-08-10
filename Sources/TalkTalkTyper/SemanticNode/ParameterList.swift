//
//  ParameterList.swift
//  
//
//  Created by Pat Nakajima on 7/23/24.
//
import TalkTalkSyntax

public struct ParameterList: SemanticNode {
	public var scope: Scope
	public var syntax: any Syntax
	public var type: any SemanticType = .void
	public var list: [(name: String, binding: Binding)]

	public var count: Int {
		list.count
	}

	public func accept<V>(_ visitor: V) -> V.Value where V : ABTVisitor {
		visitor.visit(self)
	}
}
