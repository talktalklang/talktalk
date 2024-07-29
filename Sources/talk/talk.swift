//
//  talk.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

import Foundation
import ArgumentParser

enum ProgramInput {
	case path(String), string(String), stdin
}

protocol TalkTalkCommand: AsyncParsableCommand {}

extension TalkTalkCommand {
	func get(input: String) throws -> ProgramInput {
		let filename: String
		let source: String

		if FileManager.default.fileExists(atPath: input) {
			filename = input
			source = try String(contentsOfFile: input)
		} else {
			filename = "<stdin>"
			source = input
		}

		return .string(source)
	}
}

@main
struct TalkCommand: TalkTalkCommand {
	static let version = "talk v0.0.1"

	static let configuration = CommandConfiguration(
		commandName: "talk",
		abstract: "The TalkTalk programming lanaguage",
		version: version,
		subcommands: [AST.self, Format.self]
	)
}
