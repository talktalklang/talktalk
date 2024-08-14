//
//  Driver.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import Foundation
import TalkTalkBytecode
import TalkTalkSyntax
import TalkTalkCompiler

public struct Driver {
	let directories: [URL]
	let compilationUnits: [CompilationUnit]

	public static let standardLibraryURL = Bundle.module.resourceURL!.appending(path: "Standard")

	public init(directories: [URL]) {
		self.directories = directories
		self.compilationUnits = Self.findCompilationUnits(directories: directories)
	}

	public func writeModules(to destination: URL? = nil) async throws {
		let destination = destination ?? URL.currentDirectory()

		for (name, compilationResult) in try await compile() {
			let serialized = try compilationResult.module.serialize(with: compilationResult.analysis, with: JSONEncoder())
			let filename = "\(name).tlkmodule"
			let moduleDestination = destination.appending(path: filename)
			try Data(serialized).write(to: moduleDestination)
			print("Wrote \(filename)")
		}
	}

	public func compile() async throws -> [String: CompilationResult] {
		try compilationUnits.reduce(into: [:]) { res, unit in
			res[unit.name] = try Pipeline(compilationUnit: unit).run()
		}
	}
}

fileprivate extension Driver {
	static func findCompilationUnits(directories: [URL]) -> [CompilationUnit] {
		directories.map {
			guard let enumerator = FileManager.default.enumerator(at: $0, includingPropertiesForKeys: [.nameKey]) else {
				fatalError("could not enumerate files for \($0)")
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

			return CompilationUnit(name: $0.lastPathComponent, files: fileURLs)
		}
	}

}
