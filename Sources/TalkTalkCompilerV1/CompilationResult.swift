//
//  CompilationResult.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode

public struct CompilationResult: @unchecked Sendable {
	public let module: Module
	public let analysis: AnalysisModule

	public init(module: Module, analysis: AnalysisModule) {
		self.module = module
		self.analysis = analysis
	}
}
