//
//  REPL.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import ArgumentParser
import TalkTalkVM

struct REPL: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Read! Eval?? Print. Loop?!"
	)

	func run() async throws {
		_ = try await REPLRunner.run()
	}
}
