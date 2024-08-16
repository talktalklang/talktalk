//
//  TextDocumentDefinition.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

struct TextDocumentDefinition {
	var request: Request

	func handle(_ server: Server) async {
		let params = request.params as! TextDocumentDefinitionRequest
		guard let source = await server.sources[params.textDocument.uri] else {
			Log.error("no source found for \(params.textDocument.uri)")
			return
		}

		Log.info("we got a definition request \(params) : \(source)")
	}
}
