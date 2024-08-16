//
//  Log.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import Foundation

public struct Log {
	public static func info(_ message: String) {
		log("[info] " + message)
	}

	public static func error(_ message: String) {
		FileHandle.standardError.write(Data((message + "\n").utf8))
		log("[error] " + message)
	}

	private static func log(_ message: String) {
		guard FileManager.default.fileExists(atPath: URL.homeDirectory.appending(path: "apps/talktalk/lsp.log").path) else {
			return
		}

		let logfile = URL.homeDirectory.appending(path: "apps/talktalk/lsp.log")
		try! append(data: Data(message.utf8), to: logfile)
		try! append(data: Data("\n".utf8), to: logfile)
	}

	static func append(data: Data, to fileURL: URL) throws {
		if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
			defer {
				fileHandle.closeFile()
			}
			fileHandle.seekToEndOfFile()
			fileHandle.write(data)
		} else {
			try data.write(to: fileURL, options: .atomic)
		}
	}
}
