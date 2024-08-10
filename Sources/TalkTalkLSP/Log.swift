//
//  Log.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import Foundation

public struct Log {
	public static func info(_ message: String) {
		log(message)
	}

	public static func error(_ message: String) {
		FileHandle.standardError.write(Data((message + "\n").utf8))
		log("ERROR: " + message)
	}

	private static func log(_ message: String) {
		let logfile = URL.homeDirectory.appending(path: "apps/talktalk/lsp.log")
		try! Data(message.utf8).append(to: logfile)
		try! Data("\n".utf8).append(to: logfile)
	}
}
