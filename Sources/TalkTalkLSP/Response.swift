//
//  Response.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

struct Response<Result: Codable>: Codable {
	enum CodingKeys: CodingKey {
		case id, result, jsonrpc
	}

	let id: RequestID?
	let result: Result
	let jsonrpc = "2.0"
}
