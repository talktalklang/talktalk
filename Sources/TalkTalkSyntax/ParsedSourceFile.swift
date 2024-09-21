//
//  ParsedSourceFile.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkCore

public struct ParsedSourceFile: Hashable, Equatable {
	public static func == (lhs: ParsedSourceFile, rhs: ParsedSourceFile) -> Bool {
		lhs.path == rhs.path
	}

	public let path: String
	public let syntax: [any Syntax]

	public static func tmp(_ text: String, _ path: String) -> ParsedSourceFile {
		ParsedSourceFile(
			path: path,
			// swiftlint:disable force_try
			syntax: try! Parser.parse(SourceFile(path: path, text: text))
			// swiftlint:enable force_try
		)
	}

	public init(path: String, syntax: [any Syntax]) {
		self.path = path
		self.syntax = syntax
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(path)
	}
}

extension ParsedSourceFile: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		self.path = "<literal \(value.hashValue) \(value)>"
		// swiftlint:disable force_try
		self.syntax = try! Parser.parse(.init(path: path, text: value))
		// swiftlint:enable force_try
	}
}
