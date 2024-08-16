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
		ParsedSourceFile(
			path: "/tmp/\(UUID().uuidString)",
			syntax: try! Parser.parse(SourceFile(path: "", text: text))
		)
	}

	public init(path: String, syntax: [any Syntax]) {
		self.path = path
		self.syntax = syntax
	}
}

extension ParsedSourceFile: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		self.path = "<literal>"
		self.syntax = try! Parser.parse(.init(path: "<literal>", text: value))
	}
}
