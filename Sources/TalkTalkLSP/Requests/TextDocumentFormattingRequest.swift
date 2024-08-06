//
//  TextDocumentFormattingRequest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct TextDocumentFormattingRequest: Decodable {
	let textDocument: TextDocument
	let options: FormattingOptions?
}
