//
//  SourceLocation.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public struct SourceLocation: Sendable, Equatable {
	public let start: Token
	public let end: Token

	public var line: UInt32 {
		UInt32(start.line)
	}

	public var range: Range<Int> {
		start.start..<(end.start + end.length)
	}
}

extension SourceLocation: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: Token...) {
		precondition(!elements.isEmpty, "cannot have a source location with no elements")
		start = elements.first!
		end = elements.last!
	}
}
