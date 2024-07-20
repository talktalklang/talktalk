//
//  IntType.swift
//  
//
//  Created by Pat Nakajima on 7/20/24.
//

public struct IntType: SemanticType {
	public var name = "Int"

	public func assignable(from other: any SemanticType) -> Bool {
		other is IntType
	}
}

public extension SemanticType where Self == IntType {
	static var int: IntType { IntType() }
}
