//
//  ModuleAnalyzer+Incremental.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/16/24.
//

import TalkTalkCore

public extension ModuleAnalyzer {
	mutating func addFile(_ file: ParsedSourceFile) throws -> (ModuleAnalyzer, AnalysisModule) {
		var files = files
		files.removeAll(where: { $0 == file })
		files.append(file)

		let analyzer = try ModuleAnalyzer(
			name: name,
			files: files,
			moduleEnvironment: [:],
			importedModules: []
		)

		return try (analyzer, analyzer.analyze())
	}
}
