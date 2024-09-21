//
//  Compile.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import ArgumentParser
import TalkTalkSyntax

struct Compile: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		commandName: "compile",
		abstract: "Compiles TalkTalk to byte code",
		subcommands: [
			ModuleCompile.self,
		]
	)
}
