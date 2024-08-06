//
//  Response.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

struct Response<Result: Encodable>: Encodable {
	let id: RequestID
	let result: Result
	let jsonrpc = "2.0"
}
