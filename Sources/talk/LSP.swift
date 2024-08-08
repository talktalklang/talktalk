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

	func run() async throws {
		var lsp = TalkTalkLSP.LSP()
		lsp.start()
	}
}
