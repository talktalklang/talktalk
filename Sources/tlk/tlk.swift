//
//  tlk.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

import ArgumentParser
import Foundation

@main
struct TlkCommand: AsyncParsableCommand {
	static let version = "tlk v0.0.1"

	static let configuration = CommandConfiguration(
		commandName: "tlk",
		abstract: "The TalkTalk programming lanaguage",
		version: version,
		subcommands: [Run.self, Format.self, AST.self]
	)
}
