//
//  SourceLocation.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public struct SourceLocation: Sendable, Equatable, Hashable, Codable, CustomStringConvertible {
	public let path: String
	public let start: Token
	public let end: Token

	public var description: String {
		"\(path), ln: \(start.line), col: \(start.column)"
	}

	public var line: UInt32 {
		UInt32(start.line)
	}

	public var range: Range<Int> {
		start.start ..< (end.start + end.length)
	}

	public func contains(line: Int, column: Int) -> Bool {
		if start.line != end.line {
			// If this location spans multiple lines then just see if the
			// line is within them since matching columns doesn't make as much sense.
			return line >= start.line && line <= end.line
		}

		return line >= start.line && line <= end.line &&
			column >= start.column && column <= (end.column + end.length)
	}
}

extension SourceLocation: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: Token...) {
		precondition(!elements.isEmpty, "cannot have a source location with no elements")
		self.path = elements.first!.path
		self.start = elements.first!
		self.end = elements.last!
	}
}
