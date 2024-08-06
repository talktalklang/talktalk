//
//  Untitled.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import Foundation

public struct LSP {
	var handler = Handler()

	public init() {}

	public mutating func start() {
		Log.info("starting talktalk lsp")

		let file = FileHandle.standardInput

		while true {
			let data = file.availableData
			handler.handle(data: data)
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
