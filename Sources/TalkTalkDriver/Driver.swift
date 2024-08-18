//
//  Driver.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import Foundation
import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkCore
import TalkTalkSyntax

public struct Driver {
	let directories: [URL]
	let compilationUnits: [CompilationUnit]
	let analyses: [String: AnalysisModule]
	let modules: [String: Module]

	public init(
		directories: [URL],
		analyses: [String: AnalysisModule],
		modules: [String: Module]
	) {
		self.directories = directories
		self.compilationUnits = Self.findCompilationUnits(directories: directories)
		self.analyses = analyses
		self.modules = modules
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

	public func compile(
		mode: CompilationMode = .module,
		allowErrors: Bool = false
	) async throws -> [String: CompilationResult] {
		var result: [String: CompilationResult] = [:]
		for unit in compilationUnits {
			result[unit.name] = try await Pipeline(
				compilationUnit: unit,
				mode: mode,
				analyses: analyses,
				modules: modules,
				allowErrors: allowErrors
			).run()
		}
		return result
	}
}

private extension Driver {
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
