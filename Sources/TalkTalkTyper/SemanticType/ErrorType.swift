//
//  ErrorType.swift
//
//
//  Created by Pat Nakajima on 7/20/24.
//

public struct ErrorType: SemanticType {
	public var description = "Error"

	public func assignable(from _: any SemanticType) -> Bool {
		false
	}
}

public extension SemanticType where Self == ErrorType {
	static var error: ErrorType { ErrorType() }
}
