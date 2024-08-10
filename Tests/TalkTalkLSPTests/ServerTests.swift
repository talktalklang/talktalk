//
//  ServerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import Foundation
import Testing
import TalkTalkBytecode
@testable import TalkTalkLSP

fileprivate extension Data {
	func `as`<T: Codable>(_ codable: T.Type) -> T? {
		try? JSONDecoder().decode(T.self, from: self)
	}
}

@MainActor
struct ServerTests {
	enum Err: Error {
		case err(String)
	}

	func stripHeader(from data: Data) -> Data {
		var i = 16
		var length = Data()
		while i <= data.count, data[i] != 13 {
			length.append(data[i])
			i += 1
		}

		i += 3  // Skip the \n\r\n

		return data[i..<data.count]
	}

	func responses(from requests: Request...) throws -> [Data] {
		let requestData = try Data(requests.map {
			let data = try JSONEncoder().encode($0)
			return "Content-Length: \(data.count)\r\n\r\n\(String(data: data, encoding: .utf8)!)"
		}.joined().utf8)

		var responses: [Data] = []

		var handler = Handler { request in
			var server = Server()
			let output = OutputCapture.run {
				server.handle(request)
			}

			responses.append(Data(output.stdout.utf8))
		}

		handler.handle(data: requestData)

		return responses.map { stripHeader(from: $0) }
	}

	@Test("Handles simple message") func simple() throws {
		let responses = try responses(
			from: Request(id: .integer(321), method: .initialize)
		)

		#expect(responses[0].as(InitializeResult.self) != nil)
	}

	@Test("Handles partial message") func partial() throws {
		let requestData = try JSONEncoder().encode(Request(id: .integer(321), method: .initialize))
		let data = Data("Content-Length: \(requestData.count)\r\n\r\n\(String(data: requestData, encoding: .utf8)!)".utf8)
		let data1 = data[0..<32]
		let data2 = data[32..<data.count]

		var server = Server()
		var called = false
		var handler = Handler { request in
			let output = OutputCapture.run {
				called = true
				server.handle(request)
			}

			let response = stripHeader(from: Data(output.stdout.utf8))
			let result = try! JSONDecoder().decode(InitializeResult.self, from: response)

			#expect(result != nil)
		}

		handler.handle(data: data1)
		handler.handle(data: data2)

		#expect(called == true)
	}

	@Test("Handles two messages") func twoMessages() throws {
		let responses = try responses(
			from: Request(id: .integer(321), method: .initialize),
						Request(id: .integer(123), method: .initialize)
		)

		#expect(responses[0].as(InitializeResult.self) != nil)
		#expect(responses[1].as(InitializeResult.self) != nil)
	}
}
