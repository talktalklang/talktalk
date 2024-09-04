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
		guard let params = request.params as? TextDocumentDefinitionRequest else {
			Log.error("Could not parse TextDocumentDefinitionRequest params")
			return
		}

		await Log.info("files: \(server.analyzedFilePaths)")

		if let match = await server.findDefinition(
			from: params.position,
			path: params.textDocument.uri
		) {
			await server.respond(
				to: request.id,
				with: Location(
					uri: match.location.path,
					range: Range(
						start: Position(line: match.location.start.line, character: match.location.start.column),
						end: Position(line: match.location.start.line, character: match.location.start.column + match.location.start.length)
					)
				)
			)
		}
	}
}
