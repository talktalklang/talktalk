//
//  Untitled.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import Foundation

#if os(Linux)
extension URL {
	static var homeDirectory: URL {
		let home = ProcessInfo.processInfo.environment["HOME"]!
		return URL(fileURLWithPath: home)
	}

	func appending(path: String) -> URL {
		self.appendingPathComponent(path)
	}
}
#endif

public struct LSP {
	let decoder = JSONDecoder()
	let encoder = JSONEncoder()

	let newline = Character("\n").unicodeScalars.first!.value
	let cr = Character("\r").unicodeScalars.first!.value

	public init() {}

	public func start() {
		log("starting talktalk lsp")
		let file = FileHandle.standardInput

		while true {
			let data = file.availableData
			try? data.append(to: URL.homeDirectory.appending(path: "apps/talktalk/lsp.log"))

			if data.isEmpty {
				continue
			}

			var length: Data = .init()
			var i = 16
			while i <= data.count, data[i] != 13 {
				let n = data[i]
				length.append(data[i])
				i += 1
			}

			i += 3 // Skip the \n\r\n

			if i > data.count {
				log("i less than data.count")
				continue
			}

			let body = data[i ..< data.count]

			let message: Request
			do {
				message = try decoder.decode(Request.self, from: body)
			} catch {
				log("Error parsing json: \(error)")
				continue
			}

			let msg = "\(message)"
			log("\(msg)")

			switch message.method {
			case "initialize":
				let response = InitializeResult()
				respond(to: message.id, with: response)
			default:
				log("unknown method: \(message.method)")
			}

		}
	}

	public func accept(string: String) -> String {
		"Message"
	}

	func respond<T: Encodable>(to id: RequestID, with response: T) {
		do {
			let response = Response(id: id, result: response)
			let content = try encoder.encode(response)
			let contentLength = content.count
			var data = Data("Content-Length: \(contentLength)\r\n\r\n".utf8)
			data.append(content)
			let dataString = String(data: data, encoding: .utf8)!
			try? data.append(to: URL.homeDirectory.appending(path: "apps/talktalk/lsp.log"))

			print(dataString)
		} catch {
			log("error generating response: \(error)")
		}
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
