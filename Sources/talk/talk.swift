//
//  talk.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

import ArgumentParser
import Foundation
import TalkTalkSyntax

enum ProgramInput {
	case path(SourceFile), string(String), stdin
}

public protocol TalkTalkCommand: AsyncParsableCommand {}

public extension TalkTalkCommand {
	func get(input: String) throws -> SourceFile {
		let filename: String
		let source: String

		if FileManager.default.fileExists(atPath: input) {
			filename = input
			source = try String(contentsOf: URL.currentDirectory().appending(path: input), encoding: .utf8)
		} else {
			filename = "<stdin>"
			source = input
		}

		return SourceFile(path: filename, text: source)
	}
}

@main
struct TalkCommand: TalkTalkCommand {
	static let version = "talk v0.0.1"

	static let configuration = CommandConfiguration(
		commandName: "talk",
		abstract: "The TalkTalk programming lanaguage",
		version: version,
		subcommands: [
			AST.self,
			Format.self,
			REPL.self,
			Interpret.self,
			LSP.self,
			Compile.self,
			AnalysisPrinter.self,
		]
	)
}
