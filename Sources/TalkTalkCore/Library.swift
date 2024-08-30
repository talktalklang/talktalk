//
//  Library.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import Foundation

public struct Library {
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
		#if DEBUG
			Bundle.module.resourceURL!
		#else
			URL.currentDirectory().appending(path: "Library")
		#endif
	}

	// This is the standard library. It's kind of a big deal.
	static var standard: Library {
		Library(
			name: "Standard",
			location: libraryURL.appending(path: "Standard"),
			paths: [
				"Int.tlk",
				"String.tlk",
				"Array.tlk",
				"Dictionary.tlk"
			]
		)
	}

	static var standardLibraryURL: URL {
		libraryURL.appending(path: "Standard")
	}

	static var replURL: URL {
		libraryURL.appending(path: "REPL")
	}

	static func files(for url: URL) -> Set<URL> {
		guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.nameKey]) else {
			fatalError("could not enumerate files for \(url)")
		}

		var fileURLs: Set<URL> = []
		for case let fileURL as URL in enumerator {
			guard let resourceValues = try? fileURL.resourceValues(forKeys: [.nameKey, .isDirectoryKey]),
						let isDirectory = resourceValues.isDirectory
			else {
				print("skipping \(fileURL)")
				continue
			}

			if !isDirectory, fileURL.pathExtension == "tlk" {
				fileURLs.insert(fileURL)
			}
		}

		return fileURLs
	}
}
