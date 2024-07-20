//
//  BoolType.swift
//  
//
//  Created by Pat Nakajima on 7/20/24.
//

public struct BoolType: SemanticType {
	public var description = "Bool"

	public func assignable(from other: any SemanticType) -> Bool {
		other is BoolType
	}
}

public extension SemanticType where Self == BoolType {
	static var bool: BoolType { BoolType() }
}
