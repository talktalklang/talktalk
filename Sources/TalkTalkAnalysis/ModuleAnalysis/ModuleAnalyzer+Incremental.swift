//
//  ModuleAnalyzer+Incremental.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/16/24.
//

import TalkTalkSyntax

public extension ModuleAnalyzer {
	mutating func addFile(_ file: ParsedSourceFile) throws -> AnalysisModule {
		files.removeAll(where: { $0 == file })
		files.append(file)
		return try analyze()
	}
}
