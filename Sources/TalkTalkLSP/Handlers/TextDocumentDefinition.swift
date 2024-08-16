//
//  TextDocumentDefinition.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

import TalkTalkAnalysis

struct TextDocumentDefinition {
	var request: Request

	func handle(_ server: Server) async {
		let params = request.params as! TextDocumentDefinitionRequest
		guard let source = await server.sources[params.textDocument.uri] else {
			Log.error("no source found for \(params.textDocument.uri)")
			return
		}

		if let match = await server.findDefinition(from: params.position, path: params.textDocument.uri) {
			await server.respond(
				to: request.id,
				with: Location(
					uri: match.token.path,
					range: Range(
						start: Position(line: match.token.line, character: match.token.column),
						end: Position(line: match.token.line, character: match.token.column + match.token.length)
					)
				)
			)
		}
	}
}
