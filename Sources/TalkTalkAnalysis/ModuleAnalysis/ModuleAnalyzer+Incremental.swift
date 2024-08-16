//
//  AnalysisModule+Incremental.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/16/24.
//

import TalkTalkSyntax

public extension ModuleAnalyzer {
	mutating func addFile(_ file: ParsedSourceFile) throws -> AnalysisModule {
		self.files.remove(file)
		self.files.insert(file)
		return try self.analyze()
	}
}
