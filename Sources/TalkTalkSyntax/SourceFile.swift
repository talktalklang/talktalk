//
//  SourceFile.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import Foundation

public struct SourceFile {
	public let path: String
	public let text: String

	public static func tmp(_ text: String) -> SourceFile {
		SourceFile(path: "/tmp/\(UUID().uuidString)", text: text)
	}

	public init(path: String, text: String) {
		self.path = path
		self.text = text
	}
}

extension SourceFile: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		self.path = "<literal>"
		self.text = value
	}
}
