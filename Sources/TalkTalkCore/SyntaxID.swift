//
//  SyntaxID.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/31/24.
//

import Foundation

public struct SyntaxID: Hashable, Sendable, Codable, CustomStringConvertible {
	public let id: Int
	public let path: String

	public init(id: Int, path: String) {
		self.id = id
		self.path = path

		#if DEBUG
			// swiftlint:disable fatal_error
			if path.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
				fatalError("empty path not allowed")
			}
			// swiftlint:enable fatal_error
		#endif
	}

	public static func synthetic(_ name: String) -> SyntaxID {
		SyntaxID(id: name.hashValue, path: name)
	}

	public var description: String {
		"SyntaxID(\(id), \(path))"
	}
}

extension SyntaxID: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: Int) {
		self.id = value
		self.path = "synthetic"
	}
}
