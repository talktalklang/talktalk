//
//  Library.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import Foundation

public struct Library {
	static let talktalkLibraryEnvKey = "TALKTALK_BUNDLE_PATH"

	// The name of this library
	public let name: String

	// Where its root is
	public let location: URL

	// A list of files. Can be order dependent.
	public let paths: [String]
}

// Helpers
public extension Library {
	static var libraryURL: URL {
		if let bundlePath = ProcessInfo.processInfo.environment[talktalkLibraryEnvKey] {
			if FileManager.default.fileExists(atPath: bundlePath), let url = URL(string: bundlePath) {
				return url
			} else {
				print("Could not find bundle path from environment key: \(talktalkLibraryEnvKey)")
				fatalError("No bundle found.")
			}
		} else {
			// swiftlint:disable force_unwrapping
			return Bundle.module.resourceURL!
			// swiftlint:enable force_unwrapping
		}
	}

	// This is the standard library. It's kind of a big deal.
	static var standard: Library {
		Library(
			name: "Standard",
			location: libraryURL.appending(path: "Standard"),
			paths: [
				"Int.talk",
				"String.talk",
				"Array.talk",
				"Dictionary.talk",
			]
		)
	}

	static var replURL: URL {
		libraryURL.appending(path: "REPL")
	}
}
