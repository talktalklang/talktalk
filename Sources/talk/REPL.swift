//
//  REPL.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import ArgumentParser
import TalkTalkLSP

struct REPL: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Read! Eval?? Print. Loop?!"
	)

	@MainActor
	func run() async throws {
		Log.info("talk lsp called")
		var lsp = TalkTalkLSP.LSP()
		lsp.start()
	}
}
