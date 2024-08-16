//
//  SourceLocation.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public struct SourceLocation: Sendable, Equatable, Hashable {
	public let path: String
	public let start: Token
	public let end: Token

	public var line: UInt32 {
		UInt32(start.line)
	}

	public var range: Range<Int> {
		start.start..<(end.start + end.length)
	}

	public func contains(line: Int, column: Int) -> Bool {
		line >= start.line && line <= end.line &&
			column >= start.column && column <= (end.column + end.length)
	}
}

extension SourceLocation: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: Token...) {
		precondition(!elements.isEmpty, "cannot have a source location with no elements")
		path = elements.first!.path
		start = elements.first!
		end = elements.last!
	}
}
