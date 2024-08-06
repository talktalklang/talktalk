import Foundation

struct Handler {
	let decoder = JSONDecoder()
	let encoder = JSONEncoder()

	let newline = Character("\n").unicodeScalars.first!.value
	let cr = Character("\r").unicodeScalars.first!.value

	let stdout = FileHandle.standardOutput

	func handle(data: Data) {
		if data.isEmpty {
			return
		}

		log(String(data: data, encoding: .utf8)!)

		var length: Data = .init()
		var i = 16
		while i <= data.count, data[i] != 13 {
			length.append(data[i])
			i += 1
		}

		i += 3  // Skip the \n\r\n

		if i > data.count {
			log("i less than data.count")
			return
		}

		let body = data[i..<data.count]

		let message: Request
		do {
			message = try decoder.decode(Request.self, from: body)
		} catch {
			log("Error parsing json: \(error)")
			return
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

	func respond<T: Encodable>(to id: RequestID?, with response: T) {
		do {
			let response = Response(id: id, result: response)
			let content = try encoder.encode(response)
			let contentLength = content.count
			var data = Data("Content-Length: \(contentLength)\r\n\r\n".utf8)
			data.append(content)
			try stdout.write(contentsOf: data)

			let dataString = String(data: data, encoding: .utf8)!
			log(dataString)
		} catch {
			log("error generating response: \(error)")
		}
	}

	func log(_ msg: String) {
		try! Data(msg.utf8).append(to: URL.homeDirectory.appending(path: "apps/talktalk/lsp.log"))
		try! Data("\n".utf8).append(to: URL.homeDirectory.appending(path: "apps/talktalk/lsp.log"))
	}

}
