//
//  LSP.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import ArgumentParser
import TalkTalkCore
import TalkTalkLSP

struct LSP: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Run the TalkTalk LSP server"
	)

	func run() async throws {
		try await TalkTalkLSP.LSP().start()
	}
}
