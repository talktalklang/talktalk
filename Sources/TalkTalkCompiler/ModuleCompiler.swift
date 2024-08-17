//
//  ModuleCompiler.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkSyntax

public struct ModuleCompiler {
	let name: String
	let analysisModule: AnalysisModule
	let moduleEnvironment: [String: Module]

	public init(
		name: String,
		analysisModule: AnalysisModule,
		moduleEnvironment: [String: Module] = [:]
	) {
		self.name = name
		self.analysisModule = analysisModule
		self.moduleEnvironment = moduleEnvironment
	}

	public func compile(mode: CompilationMode) throws -> Module {
		let module = CompilingModule(
			name: name,
			analysisModule: analysisModule,
			moduleEnvironment: moduleEnvironment
		)

		for file in analysisModule.analyzedFiles {
			try module.compile(file: file)
		}

		return module.finalize(mode: mode)
	}
}
