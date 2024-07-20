//
//  Function.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct FunctionType: SemanticType {
	public var returns: any SemanticType

	public var name: String {
		"Function -> (\(returns.name))"
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

public struct Function: SemanticNode {
	public var syntax: FunctionDeclSyntax
	public var binding: Binding
	public var prototype: FunctionType

	public var type: any SemanticType {
		prototype
	}
}
