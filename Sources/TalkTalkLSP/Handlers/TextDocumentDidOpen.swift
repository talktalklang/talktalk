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
		let params = request.params as! TextDocumentDidOpenRequest
		await server.setSource(uri: params.textDocument.uri, to: .init(textDocument: params.textDocument))
		Log.info("didopen \(params.textDocument.uri)")
	}
}
