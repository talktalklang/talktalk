//
//  TextDocumentDidChange.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct TextDocumentDidChange {
	var request: Request

	func handle(_ server: inout Server) {
		let params = request.params as! TextDocumentDidChangeRequest
		let source = server.sources[params.textDocument.uri] ?? SourceDocument(
			version: params.textDocument.version,
			uri: params.textDocument.uri,
			text: params.contentChanges[0].text
		)

		source.update(text: params.contentChanges[0].text)
	}
}
