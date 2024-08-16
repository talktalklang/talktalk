//
//  TextDocumentDidChange.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct TextDocumentDidChange {
	var request: Request

	func handle(_ server: Server) async {
		let params = request.params as! TextDocumentDidChangeRequest
		let source = if let source = await server.sources[params.textDocument.uri] {
			source
		} else {
			await SourceDocument(
				version: params.textDocument.version,
				uri: params.textDocument.uri,
				text: params.contentChanges[0].text
			)
		}

		await source.update(text: params.contentChanges[0].text)
		await server.analyze()
	}
}
