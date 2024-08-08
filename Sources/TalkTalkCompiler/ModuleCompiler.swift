//
//  ModuleCompiler.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode
import TalkTalkAnalysis
import TalkTalkSyntax

public struct ModuleCompiler {
	let name: String
	let analysisModule: AnalysisModule

	public init(name: String, analysisModule: AnalysisModule) {
		self.name = name
		self.analysisModule = analysisModule
	}

	public func compile() throws -> Module {
		let module = CompilingModule(name: name, analysisModule: analysisModule)

		for file in analysisModule.analyzedFiles {
			try module.compile(file: file)
		}

		return module.finalize()
	}
}
