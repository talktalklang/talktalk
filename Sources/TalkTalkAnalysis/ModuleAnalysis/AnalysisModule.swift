//
//  AnalysisModule.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkSyntax
import TalkTalkBytecode

public struct AnalysisModule {
	public let name: String
	public let files: [ParsedSourceFile]

	// The list of globals in this module
	public var globals: [String: ModuleGlobal] = [:]

	// A list of modules this module imports
	public var imports: [Module] = []

	public func global(named name: String) -> ModuleGlobal? {
		globals[name]
	}
}
