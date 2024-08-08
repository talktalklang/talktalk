//
//  AnalysisModule.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import Foundation
import TalkTalkSyntax
import TalkTalkBytecode

public struct AnalysisModule {
	public let name: String

	public let files: [ParsedSourceFile]

	// The list of analyzed files for this module (this is built up by the module analyzer)
	public var analyzedFiles: [AnalyzedSourceFile] = []

	// The list of globals in this module
	public var globals: [String: ModuleGlobal] = [:]

	// A list of modules this module imports
	public var imports: [String: ModuleGlobal] = [:]

	public func global(named name: String) -> ModuleGlobal? {
		globals[name]
	}
}

public extension AnalysisModule {
	static func empty(_ name: String) -> AnalysisModule {
		AnalysisModule(name: name, files: [])
	}
}
