//
//  Message.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

import Foundation
import TalkTalkBytecode

struct MessageParams: Equatable {}

enum RequestID: Equatable, Codable {
	case integer(Int), string(String)

	init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		if let id = try? container.decode(Int.self) {
			self = .integer(id)
		} else if let id = try? container.decode(String.self) {
			self = .string(id)
		} else {
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

struct Request: Equatable, Decodable {
	static func == (lhs: Request, rhs: Request) -> Bool {
		lhs.id == rhs.id && lhs.method == rhs.method
	}
	
	enum Params: Equatable {
		case object(MessageParams), array([MessageParams])
	}

	var id: RequestID?
	var method: String
	var params: (any Decodable)?

	enum CodingKeys: CodingKey {
		case id, method, params
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try container.decodeIfPresent(RequestID.self, forKey: .id)
		self.method = try container.decode(String.self, forKey: .method)
		self.params = switch Method(rawValue: self.method) {
		case .initialize:
			nil
		case .initialized:
			nil
		case .textDocumentCompletion:
			try container.decode(TextDocumentCompletionRequest.self, forKey: .params)
		case .textDocumentDidChange:
			try container.decode(TextDocumentDidChangeRequest.self, forKey: .params)
		default:
			nil
		}
	}
}
