//
//  Interpret.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

import TalkTalk
import ArgumentParser

struct Interpret: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Run the given input in the tree walking interpreter"
	)

	@Argument(help: "The input to format.")
	var input: String

	func run() async throws {
		let source = try get(input: input).text
		try print(Interpreter(source).evaluate())
	}
}
