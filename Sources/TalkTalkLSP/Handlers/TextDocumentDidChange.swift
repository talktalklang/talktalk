//
//  TextDocumentDidChange.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct TextDocumentDidChange {
	var request: Request

	func handle(_ handler: inout Handler) {
		let params = request.params as! TextDocumentDidChangeRequest
		handler.sources[params.textDocument.uri] = .init(uri: params.textDocument.uri, text: params.contentChanges[0].text)
	}
}
