//
//  Library.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import Foundation

public struct Library {
	static var libraryURL: URL { Bundle.module.resourceURL! }
	public static var standardLibraryURL: URL { libraryURL.appending(path: "Standard") }
	public static var replURL: URL { libraryURL.appending(path: "REPL") }

	public static func files(for url: URL) -> [URL] {
		guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.nameKey]) else {
			fatalError("could not enumerate files for \(url)")
		}

		var fileURLs: [URL] = []
		for case let fileURL as URL in enumerator {
			guard let resourceValues = try? fileURL.resourceValues(forKeys: [.nameKey, .isDirectoryKey]),
						let isDirectory = resourceValues.isDirectory
			else {
				print("skipping \(fileURL)")
				continue
			}

			if !isDirectory, fileURL.pathExtension == "tlk" {
				fileURLs.append(fileURL)
			}
		}

		return fileURLs
	}
}

