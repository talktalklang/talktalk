//
//  TextDocumentFormatting.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import Foundation
import TalkTalkSyntax

struct TextDocumentFormatting {
	var request: Request

	func readFromDisk(uri: String) async -> SourceDocument? {
		guard let url = URL(string: uri) else {
			return nil
		}

		guard let string = try? String(contentsOf: url, encoding: .utf8) else {
			return nil
		}

		return await SourceDocument(version: nil, uri: uri, text: string)
	}

	func handle(_ server: Server) async {
		guard let params = request.params as? TextDocumentFormattingRequest else {
			Log.error("Could not parse TextDocumentFormattingRequest params")
			return
		}

		var source = await server.sources[params.textDocument.uri]
		if source == nil {
			source = await readFromDisk(uri: params.textDocument.uri)
		}

		guard let source else {
			Log.error("could not find source for document uri")
			return
		}

		do {
			let formatted = try await Formatter(input: .init(path: source.uri, text: source.text)).format()
			await server.respond(to: request.id, with: [TextEdit(range: source.range, newText: formatted)])
		} catch {
			Log.error("Error formatting: \(error)")
		}
	}
}
