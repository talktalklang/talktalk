//
//  TextDocumentDefinitionRequest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

struct TextDocumentDefinitionRequest: Decodable {
	let position: Position
	let textDocument: TextDocument
}
