//
//  TextDocumentDidOpen.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct TextDocumentDidOpen {
	var request: Request

	func handle(_ handler: inout Handler) {
		let params = request.params as! TextDocumentDidOpenRequest
		handler.sources[params.textDocument.uri] = .init(textDocument: params.textDocument)
	}
}
