//
//  Log.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import Foundation

struct Log {
	static func info(_ message: String) {
		log(message)
	}

	static func error(_ message: String) {
		log("ERROR: " + message)
	}

	private static func log(_ message: String) {
		try! Data(message.utf8).append(to: URL.homeDirectory.appending(path: "apps/talktalk/lsp.log"))
		try! Data("\n".utf8).append(to: URL.homeDirectory.appending(path: "apps/talktalk/lsp.log"))
	}
}
