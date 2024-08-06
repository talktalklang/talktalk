//
//  TextDocumentDidChangeRequest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct TextDocumentDidChangeRequest: Decodable {
	let contentChanges: [ContentChange]
	let textDocument: TextDocument
}
