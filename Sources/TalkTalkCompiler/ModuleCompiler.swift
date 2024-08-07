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
	let files: [ParsedSourceFile]

	public init(name: String, files: [ParsedSourceFile]) {
		self.name = name
		self.files = files
	}

	public func compile() throws -> Module {
		Module(name: name)
	}
}
