//
//  AnyType.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

public struct UnknownType: SemanticType {
	public var name = "Unknown"

	public func assignable(from other: any SemanticType) -> Bool {
		true
	}
}
