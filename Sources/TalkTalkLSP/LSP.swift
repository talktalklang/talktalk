//
//  Untitled.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import Foundation

public actor LSP {
	var server: Server
	var serverTask: Task<Void, Never>?

	public init() async throws {
		self.server = try await Server()
	}

	public func start() async {
		Log.info("starting talktalk lsp")

		let file = FileHandle.standardInput
		var handler = Handler(callback: receive)

		while true {
			let data = file.availableData
			handler.handle(data: data)
		}
	}

	func receive(_ request: Request) {
		self.server.enqueue(request)
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
