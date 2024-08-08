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

	// The list of global values in this module
	public var values: [String: ModuleValue] = [:]

	// The list of top level functions in this module
	public var functions: [String: ModuleFunction] = [:]

	// A list of modules this module imports
	public var imports: [String: ModuleGlobal] = [:]

	public func moduleValue(named name: String) -> ModuleValue? {
		values[name]
	}

	public func moduleFunction(named name: String) -> ModuleFunction? {
		functions[name]
	}

	public func moduleGlobal(named name: String) -> (any ModuleGlobal)? {
		moduleFunction(named: name) ?? moduleValue(named: name)
	}
}

public extension AnalysisModule {
	static func empty(_ name: String) -> AnalysisModule {
		AnalysisModule(name: name, files: [])
	}
}
