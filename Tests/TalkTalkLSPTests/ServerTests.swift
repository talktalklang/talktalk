//
//  ServerTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import Foundation
import TalkTalkBytecode
@testable import TalkTalkLSP
import Testing

private extension Data {
	func `as`<T: Codable>(_: T.Type) -> T? {
		try? JSONDecoder().decode(T.self, from: self)
	}
}

@Suite(.disabled()) actor ServerTests {
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

		i += 3 // Skip the \n\r\n

		return data[i ..< data.count]
	}

	func responses(from requests: Request...) async throws -> [Data] {
		var responses: [Data] = []
		let server = try await Server()

		for request in requests {
			await server.perform(request)
		}

		return responses.map { stripHeader(from: $0) }
	}

	@Test("Handles simple message") func simple() async throws {
		let responses = try await responses(
			from: Request(id: .integer(321), method: .initialize)
		)

		#expect(responses[0].as(InitializeResult.self) != nil)
	}

	@Test("Handles partial message") func partial() async throws {
		let requestData = try JSONEncoder().encode(Request(id: .integer(321), method: .initialize))
		let data = Data("Content-Length: \(requestData.count)\r\n\r\n\(String(data: requestData, encoding: .utf8)!)".utf8)
		let data1 = data[0 ..< 32]
		let data2 = data[32 ..< data.count]

		let server = try await Server()
		var handler = Handler(server: server)

		await handler.handle(data: data1)
		await handler.handle(data: data2)
	}

	@Test("Handles two messages") func twoMessages() async throws {
		let responses = try await responses(
			from: Request(id: .integer(321), method: .initialize),
			Request(id: .integer(123), method: .initialize)
		)

		#expect(responses[0].as(InitializeResult.self) != nil)
		#expect(responses[1].as(InitializeResult.self) != nil)
	}
}
