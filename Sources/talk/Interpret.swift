//
//  Interpret.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

import TalkTalk
import ArgumentParser

struct Interpret: TalkTalkCommand {
	@Argument(help: "The input to format.")
	var input: String

	func run() async throws {
		let source = switch try get(input: input) {
		case .path(let string):
			string
		case .stdin:
			fatalError("not yet")
		case .string(let string):
			string
		}

		try print(Interpreter(source).evaluate())
	}
}
