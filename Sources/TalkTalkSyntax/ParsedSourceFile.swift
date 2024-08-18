//
//  ParsedSourceFile.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import Foundation

public struct ParsedSourceFile: Hashable, Equatable {
	public static func == (lhs: ParsedSourceFile, rhs: ParsedSourceFile) -> Bool {
		lhs.path == rhs.path
	}

	public let path: String
	public let syntax: [any Syntax]

	public static func tmp(_ text: String, path: String = "temp-chunk/\(UUID().uuidString)") -> ParsedSourceFile {
		ParsedSourceFile(
			path: path,
			syntax: try! Parser.parse(SourceFile(path: "", text: text))
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
		self.path = "<literal \(value)>"
		self.syntax = try! Parser.parse(.init(path: "<literal \(value)>", text: value))
	}
}
