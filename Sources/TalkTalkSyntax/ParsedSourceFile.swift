//
//  ParsedSourceFile.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import Foundation

public struct ParsedSourceFile {
	public let path: String
	public let syntax: [any Syntax]

	public static func tmp(_ text: String) -> ParsedSourceFile {
		ParsedSourceFile(path: "/tmp/\(UUID().uuidString)", syntax: Parser.parse(text))
	}
}
