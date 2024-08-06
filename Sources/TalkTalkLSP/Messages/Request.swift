//
//  Message.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import Foundation
import OSLog
import TalkTalkBytecode

struct MessageParams: Equatable {}

private let logger = Logger(subsystem: "talktalk", category: "lsp")

enum RequestID: Equatable, Codable {
	case integer(Int), string(String)

	init(from decoder: any Decoder) throws {
		logger.error("decoding ID")
		let container = try decoder.singleValueContainer()
		if let id = try? container.decode(Int.self) {
			logger.error("got int id: \(id)")
			self = .integer(id)
		} else if let id = try? container.decode(String.self) {
			logger.error("got string id \(id, privacy: .public)")
			self = .string(id)
		} else {
			logger.error("could not decode id")
			fatalError("could not decode id")
		}
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()

		switch self {
		case .integer(let int):
			try container.encode(int)
		case .string(let string):
			try container.encode(string)
		}
	}
}

struct Request: Equatable, Codable {
	enum Params: Equatable {
		case object(MessageParams), array([MessageParams])
	}

	var id: RequestID
	var method: String
}
