//
//  TextDocument.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct TextDocument: Decodable {
	let uri: String
	let version: Int?
	let text: String?
}
