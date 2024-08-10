//
//  SemanticNode.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public protocol SemanticType: Hashable {
	var description: String { get }
	var isKnown: Bool { get }
	func assignable(from other: any SemanticType) -> Bool
}

public extension SemanticType {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	var isKnown: Bool {
		true
	}
}

public protocol SemanticNode: CustomStringConvertible {
	var scope: Scope { get }
	var syntax: any Syntax { get }
	var type: any SemanticType { get set }
	func accept<V: ABTVisitor>(_ visitor: V) -> V.Value
}

public extension SemanticNode {
	var description: String {
		"\(Self.self)(type: \(type.description), syntax: \(syntax.description))"
	}

	func cast<T: SemanticNode>(_: T.Type) -> T {
		self as! T
	}

	func `as`<T: SemanticNode>(_: T.Type) -> T? {
		self as? T
	}

	func `is`(_ other: any SemanticNode) -> Bool {
		let selfSyntax = syntax
		let otherSyntax = other.syntax
		return selfSyntax.hashValue == otherSyntax.hashValue
	}
}

public struct TODOType: SemanticType {
	public var description: String = "TODO"

	public func assignable(from other: any SemanticType) -> Bool {
		false
	}
}

public struct TODONode: SemanticNode {
	public var scope: Scope
	public var syntax: any Syntax
	public var type: any SemanticType = TODOType()
	public func accept<V: ABTVisitor>(_ visitor: V) -> V.Value {
		visitor.visit(self)
	}
}

public extension SemanticNode where Self == TODONode {
	@available(*, deprecated, message: "WIP")
	static func todo<T: Syntax>(
		_ syntax: T,
		_ scope: Scope
	) -> TODONode {
		TODONode(scope: scope, syntax: syntax)
	}
}
