//
//  SourceLocation.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public struct SourceLocation {
	public let start: Token
	public let end: Token

	public var line: UInt32 {
		UInt32(start.line)
	}
}

extension SourceLocation: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: Token...) {
		precondition(!elements.isEmpty, "cannot have a source location with no elements")
		start = elements.first!
		end = elements.last!
	}
}
