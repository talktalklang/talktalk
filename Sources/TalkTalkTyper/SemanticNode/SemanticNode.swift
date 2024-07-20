//
//  SemanticNode.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public protocol SemanticType: Hashable {
	var description: String { get }
	func assignable(from other: any SemanticType) -> Bool
}

public extension SemanticType {
	static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}
}

public protocol SemanticNode<Node> {
	associatedtype Node

	var scope: Scope { get }
	var syntax: Node { get }
	var type: any SemanticType { get set }
}

public extension SemanticNode {
	func cast<T: SemanticNode>(_ type: T.Type) -> T {
		self as! T
	}

	func `is`(_ other: any SemanticNode) -> Bool {
		let selfSyntax = syntax as! any Syntax
		let otherSyntax = other.syntax as! any Syntax
		return selfSyntax.hashValue == otherSyntax.hashValue
	}
}

public struct SemanticPlaceholder: SemanticNode {
	public var scope: Scope
	public var syntax = ""
	public var type: any SemanticType = UnknownType()
}

public extension SemanticNode where Self == SemanticPlaceholder {
	@available(*, deprecated, message: "WIP")
	static func placeholder(_ scope: Scope) -> SemanticPlaceholder {
		SemanticPlaceholder(scope: scope)
	}
}
