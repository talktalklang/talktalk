//
//  StringType.swift
//  
//
//  Created by Pat Nakajima on 7/20/24.
//

import TalkTalkSyntax

public struct StringType: SemanticType {
	public var description = "String"

	public func assignable(from other: any SemanticType) -> Bool {
		other is StringType
	}
}

public extension SemanticType where Self == StringType {
	static var string: StringType { StringType() }
}
