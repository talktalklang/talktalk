//
//  LSP.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import ArgumentParser
import TalkTalkLSP

struct LSP: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Run the TalkTalk LSP server"
	)

	@MainActor
	func run() async throws {
		Log.info("talk lsp called")
		var lsp = try await TalkTalkLSP.LSP()
		lsp.start()
	}
}
