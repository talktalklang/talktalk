//
//  TextDocumentDidOpen.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import TalkTalkAnalysis

struct TextDocumentDidOpen {
	var request: Request

	func handle(_ server: Server) async {
		guard let params = request.params as? TextDocumentDidOpenRequest else {
			Log.error("Could not parse TextDocumentDidOpenRequest params")
			return
		}

		await server.setSource(uri: params.textDocument.uri, to: .init(textDocument: params.textDocument))
		Log.info("didopen \(params.textDocument.uri)")
	}
}
