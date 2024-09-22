//
//  HTML.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/20/24.
//

import ArgumentParser
import TalkTalkLSP
import TalkTalkSyntax
import TalkTalkCore

struct HTML: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Syntax highlight some TalkTalk as HTML"
	)

	@ArgumentParser.Argument(help: "The input to format.", completion: .file(extensions: [".talk"]))
	var input: String

	func run() async throws {
		let source = try get(input: input)
		let formatted = try HTMLHighlighter(input: source).highlight()
		print(formatted, terminator: "")
	}
}

