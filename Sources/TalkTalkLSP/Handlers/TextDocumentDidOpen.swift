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
		// TODO: Make this an addFile method on module analyzer
		server.analyzer = await ModuleAnalyzer(
			name: "LSP",
			files: [],
			moduleEnvironment: server.analyzer.moduleEnvironment,
			importedModules: server.analyzer.environment.importedModules)
		Log.info("didopen \(params.textDocument.uri)")
	}
}
