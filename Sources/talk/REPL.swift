//
//  REPL.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import ArgumentParser
import TalkTalkCore

struct REPL: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Read! Eval?? Print. Loop?!"
	)

	@MainActor
	func run() async throws {
		REPLRunner()//.start()
	}
}
