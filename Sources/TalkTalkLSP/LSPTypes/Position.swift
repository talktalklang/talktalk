//
//  Position.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import TalkTalkSyntax

public struct Range: Codable, Sendable, Hashable {
	public let start: Position
	public let end: Position

	public init(start: Position, end: Position) {
		self.start = start
		self.end = end
	}

	public func contains(line: Int) -> Bool {
		start.line <= line && end.line >= line
	}
}

public struct Position: Codable, Sendable, Hashable, Comparable {
	public static func < (lhs: Position, rhs: Position) -> Bool {
		if lhs.line < rhs.line {
			return true
		}

		if lhs.line == rhs.line, lhs.character < rhs.character {
			return true
		}

		return false
	}

	public let line: Int
	public let character: Int

	public init(line: Int, character: Int) {
		self.line = line
		self.character = character
	}
}

public extension TalkTalkSyntax.SourceLocation {
	func contains(_ position: Position) -> Bool {
		position.line >= start.line && position.line <= end.line
	}
}
