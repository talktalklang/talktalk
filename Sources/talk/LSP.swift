//
//  LSP.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import TalkTalkLSP

struct LSP: TalkTalkCommand {
	func run() async throws {
		var lsp = TalkTalkLSP.LSP()
		lsp.start()
	}
}
