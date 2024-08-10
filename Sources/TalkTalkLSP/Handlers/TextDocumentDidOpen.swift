//
//  TextDocumentDidOpen.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct TextDocumentDidOpen {
	var request: Request

	func handle(_ server: inout Server) {
		let params = request.params as! TextDocumentDidOpenRequest
		server.sources[params.textDocument.uri] = .init(textDocument: params.textDocument)
	}
}
