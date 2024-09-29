//
//  LSP.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import Foundation
import TalkTalkCore

@MainActor
public struct LSP {
	var server: Server

	public init() async throws {
		self.server = try Server()
	}

	public func start() {
		Log.info("Starting talktalk LSP")

		let file = FileHandle.standardInput
		var handler = Handler(server: server)

		while true {
			let data = file.availableData
			handler.handle(data: data)
		}
	}
}
