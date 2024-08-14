//
//  AnalysisLibrary.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import Foundation
import TalkTalkCore
import TalkTalkSyntax

public struct AnalysisLibrary {
	let standard: AnalysisModule

	init() {
		self.standard = try! ModuleAnalyzer(
			name: "Standard",
			files: Self.files(in: Library.standardLibraryURL),
			moduleEnvironment: [:]
		).analyze()
	}

	private static func files(in url: URL) throws -> [ParsedSourceFile] {
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

		return try fileURLs.map {
			let contents = try String(contentsOf: $0, encoding: .utf8)
			return try ParsedSourceFile(path: $0.path, syntax: Parser.parse(contents, allowErrors: false))
		}
	}
}
