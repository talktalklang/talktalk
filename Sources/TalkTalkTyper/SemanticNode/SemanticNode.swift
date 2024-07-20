//
//  SemanticNode.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public protocol Value {
	
}

public protocol SemanticNode<Node> {
	associatedtype Node

	var binding: Binding { get }
	var syntax: Node { get }
}

public extension SemanticNode {
	func cast<T: SemanticNode>(_ type: T.Type) -> T {
		self as! T
	}
}

public struct SemanticPlaceholder: SemanticNode {
	public var binding: Binding
	public var syntax = ""
}

public extension SemanticNode where Self == SemanticPlaceholder {
	@available(*, deprecated, message: "WIP")
	static func placeholder(_ binding: Binding) -> SemanticPlaceholder {
		SemanticPlaceholder(binding: binding)
	}
}
