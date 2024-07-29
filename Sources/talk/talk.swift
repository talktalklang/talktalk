//
//  talk.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

import ArgumentParser

protocol TalkTalkCommand: AsyncParsableCommand {

}

@main
struct TalkCommand: TalkTalkCommand {
	static let version = "talk v0.0.1"

	static let configuration = CommandConfiguration(
		commandName: "talk",
		abstract: "The TalkTalk programming lanaguage",
		version: version,
		subcommands: [AST.self]
	)
}
