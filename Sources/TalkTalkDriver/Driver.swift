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

	public func compile(
		mode: CompilationMode = .module,
		allowErrors: Bool = false
	) async throws -> [String: CompilationResult] {
		var result: [String: CompilationResult] = [:]
		for unit in compilationUnits.sorted(by: { $0.name < $1.name }) {
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
		directories.compactMap {
			guard let enumerator = FileManager.default.enumerator(at: $0, includingPropertiesForKeys: [.nameKey]) else {
				return nil
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
