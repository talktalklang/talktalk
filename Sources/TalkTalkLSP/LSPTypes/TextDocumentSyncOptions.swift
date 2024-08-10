//
//  TextDocumentSyncOptions.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

struct TextDocumentSyncOptions: Codable {
	enum CodingKeys: CodingKey {
		case change, openClose
	}

	let change: TextDocumentSyncKind
	let openClose = true
}
