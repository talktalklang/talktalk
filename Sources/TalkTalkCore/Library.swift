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

	// A list of files. Can be order dependent.
	public let files: [SourceFile]
}

// Helpers
public extension Library {
	#if !WASM
	static var libraryURL: URL {
		if let bundlePath = ProcessInfo.processInfo.environment[talktalkLibraryEnvKey] {
			if FileManager.default.fileExists(atPath: bundlePath), let url = URL(string: bundlePath) {
				return url
			} else {
				print("Could not find bundle path from environment key: \(talktalkLibraryEnvKey)")
				// swiftlint:disable fatal_error
				fatalError("No bundle found.")
				// swiftlint:enable fatal_error
			}
		} else {
			// swiftlint:disable force_unwrapping
			return Bundle.module.resourceURL!
			// swiftlint:enable force_unwrapping
		}
	}
	#endif

	// This is the standard library. It's kind of a big deal.
	static var standard: Library {
		#if WASM
		// swiftlint:disable force_unwrapping
		return Library(
			name: "Standard",
			files: [
				SourceFile(path: "Optional.talk", text: EmbeddedStandardLibrary.files["Optional.talk"]!),
				SourceFile(path: "Iterable.talk", text: EmbeddedStandardLibrary.files["Iterable.talk"]!),
				SourceFile(path: "Int.talk", text: EmbeddedStandardLibrary.files["Int.talk"]!),
				SourceFile(path: "String.talk", text: EmbeddedStandardLibrary.files["String.talk"]!),
				SourceFile(path: "Array.talk", text: EmbeddedStandardLibrary.files["Array.talk"]!),
				SourceFile(path: "Dictionary.talk", text: EmbeddedStandardLibrary.files["Dictionary.talk"]!),
			]
		)
		// swiftlint:enable force_unwrapping
		#else
		return Library(
			name: "Standard",
			files: [
				"Optional.talk",
				"Iterable.talk",
				"Int.talk",
				"String.talk",
				"Array.talk",
				"Dictionary.talk",
			].map {
				// swiftlint:disable force_try
				try! SourceFile(
					path: libraryURL.appending(path: "Standard").appending(path: $0).path,
					text: String(contentsOf: libraryURL.appending(path: "Standard").appending(path: $0), encoding: .utf8))
				// swiftlint:enable force_try
			}
		)
		#endif
	}
}

