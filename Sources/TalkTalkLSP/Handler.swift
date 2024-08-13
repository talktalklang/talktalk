import Foundation

@MainActor
class LSPRequestParser {
	enum State {
		case contentLength, length, split, body(Int)
	}

	var buffer: [UInt8] = []
	var state: State = .contentLength
	var callback: (Request) -> Void = { _ in }

	var current = 0
	var currentLength: [UInt8] = []
	var currentBody: [UInt8] = []

	let contentLengthArray = Array("Content-Length: ").map { $0.asciiValue! }
	let cr: UInt8 = 13
	let newline: UInt8 = 10

	func parse(data: Data) {
		buffer.append(contentsOf: data)

		while let byte = next() {
			switch state {
			case .contentLength:
				contentLength(byte: byte)
			case .length:
				length(byte: byte)
			case .split:
				split(byte: byte)
			case .body(let contentLength):
				body(byte: byte, contentLength: contentLength)
			}
		}
	}

	func contentLength(byte: UInt8) {
		if current == contentLengthArray.count+1 {
			// We're done parsing the content length part, move on to the length part
			state = .length
			length(byte: byte)
			return
		}

		if contentLengthArray[current-1] == byte {
			return
		} else {
			Log.error("[contentLength] unexpected character parsing message at \(current-1): \(UnicodeScalar(byte)), expected: \(UnicodeScalar(contentLengthArray[current-1]))")
		}
	}

	func length(byte: UInt8) {
		if Character(UnicodeScalar(byte)).isNumber {
			currentLength.append(byte)
		} else if byte == cr {
			current = -1
			state = .split
		} else {
			Log.error("[length] unexpected character parsing message at \(current): \(UnicodeScalar(byte).debugDescription), expected number")
		}
	}

	// We need to listen for \n\r\n because the first \r was handled in length
	func split(byte: UInt8) {
		if current == 3 {
			let contentLength = Int(String(data: Data(currentLength), encoding: .ascii)!)!
			state = .body(contentLength)
			self.current = -1
			body(byte: byte, contentLength: contentLength)
			return
		}

		let expected: UInt8? = switch current {
		case 0: newline
		case 1: cr
		case 2: newline
		default:
			nil
		}

		guard let expected, expected == byte else {
			Log.error("[split] unexpected character parsing message at \(current): \(UnicodeScalar(byte))")
			return
		}
	}

	func body(byte: UInt8, contentLength: Int) {
		if currentBody.count == contentLength {
			complete()
			current = 1
		} else {
			currentBody.append(byte)
		}
	}

	func next() -> UInt8? {
		if buffer.isEmpty {
			complete()
			return nil
		}

		defer {
			current += 1
		}

		return buffer.removeFirst()
	}

	func complete() {
		guard case let .body(contentLength) = state, currentBody.count == contentLength else {
			return
		}

		let data = Data(currentBody)
		do {
			let request = try JSONDecoder().decode(Request.self, from: data)

			current = 0
			currentBody = []
			currentLength = []
			state = .contentLength

			self.callback(request)
		} catch {
			Log.error("error parsing json: \(error)")
			Log.error("--")
			Log.error(String(data: data, encoding: .utf8) ?? "<invalid string>")
		}
	}
}

@MainActor
struct Handler {
	// We read json, we write json
	let decoder = JSONDecoder()
	let encoder = JSONEncoder()

	// Parses incoming data over stdin and emits requests
	var parser: LSPRequestParser

	// Keep track of how many empty responses we get. If it goes to 10 we should just exit.
	var emptyResponseCount: Int = 0

	init(callback: @escaping (Request) -> Void) {
		self.parser = .init()
		self.parser.callback = callback
	}

	mutating func handle(data: Data) {
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

		parser.parse(data: data)
	}
}
