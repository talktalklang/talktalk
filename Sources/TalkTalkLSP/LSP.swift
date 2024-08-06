//
//  Untitled.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import Foundation

public struct LSP {
	public init() {}

	public func start() {
		log("starting talktalk lsp")
		let file = FileHandle.standardInput

		while true {
			let data = file.availableData
			Handler().handle(data: data)
		}
	}

	public func accept(string: String) -> String {
		"Message"
	}

	func log(_ msg: String) {
		try! Data(msg.utf8).append(to: URL.homeDirectory.appending(path: "apps/talktalk/lsp.log"))
		try! Data("\n".utf8).append(to: URL.homeDirectory.appending(path: "apps/talktalk/lsp.log"))
	}
}

extension Data {
	func append(to fileURL: URL) throws {
		if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
			defer {
				fileHandle.closeFile()
			}
			fileHandle.seekToEndOfFile()
			fileHandle.write(self)
		} else {
			try write(to: fileURL, options: .atomic)
		}
	}
}
