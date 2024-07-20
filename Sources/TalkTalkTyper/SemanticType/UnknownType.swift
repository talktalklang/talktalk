//
//  UnknownType.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

public struct UnknownType: SemanticType {
	public var description = "Unknown"

	public func assignable(from _: any SemanticType) -> Bool {
		true
	}
}

public extension SemanticType where Self == UnknownType {
	static var unknown: UnknownType { UnknownType() }
}
