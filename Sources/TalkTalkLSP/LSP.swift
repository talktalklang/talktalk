//
//  Untitled.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import Foundation

@MainActor
public struct LSP {
	var server: Server
	var serverTask: Task<Void, Never>?

	public init() async throws {
		self.server = try await Server()
	}

	public mutating func start() async {
		Log.info("starting talktalk lsp")

		let file = FileHandle.standardInput
		var handler = Handler()

		self.serverTask = Task {
			while true {
				let data = file.availableData
				handler.handle(data: data)
			}
		}

		for await request in handler.receive() {
			await self.server.handle(request)
		}
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
