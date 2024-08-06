import Foundation

struct Handler {
	// We read json, we write json
	let decoder = JSONDecoder()
	let encoder = JSONEncoder()

	// Responses are just written to stdout
	let stdout = FileHandle.standardOutput

	// Keep track of our files
	var sources: [String: String] = [:]

	// Keep track of how many empty responses we get. If it goes to 10 we should just exit.
	var emptyResponseCount: Int = 0

	mutating func handle(data: Data) {
		Log.info("handling. empty response count: \(emptyResponseCount)")

		if data.isEmpty {
			emptyResponseCount += 1
			Log.info("incrementing empty response count. now: \(emptyResponseCount)")

			if emptyResponseCount > 10 {
				Log.error("got 10 empty responses, shutting down")
				exit(0)
			}

			return
		}

		emptyResponseCount = 0

		var length: Data = .init()
		var i = 16
		while i <= data.count, data[i] != 13 {
			length.append(data[i])
			i += 1
		}

		i += 3  // Skip the \n\r\n

		if i > data.count {
			Log.error("i less than data.count")
			return
		}

		let body = data[i..<data.count]

		let request: Request
		do {
			request = try decoder.decode(Request.self, from: body)
		} catch {
			Log.error("Error parsing json: \(error)")
			return
		}

		let msg = "\(request)"
		Log.info("\(msg)")

		guard let method = Method(rawValue: request.method) else {
			Log.error("unknown method: \(request.method)")
			return
		}

		switch method {
		case .initialize:
			respond(to: request.id, with: InitializeResult())
		case .initialized:
			() // We don't do anything for this message yet.
		case .textDocumentDidChange:
			TextDocumentDidChange(request: request).handle(&self)
		case .textDocumentCompletion:
			TextDocumentCompletion(request: request).handle(&self)
		case .shutdown:
			Log.info("shutting down!")
			exit(0)
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
			Log.info(dataString)
		} catch {
			Log.error("error generating response: \(error)")
		}
	}
}
