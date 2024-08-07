//
//  Position.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import TalkTalkSyntax

public struct Range: Codable {
	public let start: Position
	public let end: Position
}

public struct Position: Codable {
	public let line: Int
	public let character: Int
}

public extension TalkTalkSyntax.SourceLocation {
	func contains(_ position: Position) -> Bool {
		position.line >= start.line && position.line <= end.line
	}
}
