//
//  VoidType.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

public struct VoidType: SemanticType {
	public var description = "Void"

	public func assignable(from other: any SemanticType) -> Bool {
		false
	}
}

public extension SemanticType where Self == VoidType {
	static var void: VoidType { VoidType() }
}
