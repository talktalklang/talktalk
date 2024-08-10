//
//  Function.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct FunctionType: SemanticType {
	public var name: String
	public var parameters: ParameterList
	public var returns: any SemanticType

	public var description: String {
		let params = parameters.list.map { (key, val) in
			"\(key): \(val.node.type.description)"
		}.joined(separator: ", ")

		return "Function(\(params)) -> (\(returns.description))"
	}

	public func assignable(from other: any SemanticType) -> Bool {
		if let other = other as? FunctionType {
			return other.returns.hashValue == returns.hashValue
		}

		return false
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(returns)
	}
}

public struct Function: SemanticNode, Declaration {
	public var name: String
	public var syntax: any Syntax
	public var scope: Scope
	public var prototype: FunctionType
	public var body: Block

	public var type: any SemanticType {
		get {
			prototype
		}

		set {
			prototype = newValue as! FunctionType
		}
	}

	public func accept<V: ABTVisitor>(_ visitor: V) -> V.Value {
		visitor.visit(self)
	}
}
