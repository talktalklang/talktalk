//
//  Position.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import TalkTalkSyntax

struct Range: Encodable {
	let start: Position
	let end: Position
}

struct Position: Codable {
	let line: Int
	let character: Int
}

extension TalkTalkSyntax.SourceLocation {
	func contains(_ position: Position) -> Bool {
		position.line >= start.line && position.line <= end.line
	}
}
