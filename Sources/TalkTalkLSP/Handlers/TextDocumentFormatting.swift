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

	func readFromDisk(uri: String) -> SourceDocument? {
		guard let url = URL(string: uri) else {
			return nil
		}

		guard let string = try? String(contentsOf: url, encoding: .utf8) else {
			return nil
		}

		return SourceDocument(version: nil, uri: uri, text: string)
	}

	func handle(_ handler: inout Handler) {
		let params = request.params as! TextDocumentFormattingRequest
		guard let source = handler.sources[params.textDocument.uri] ?? readFromDisk(uri: params.textDocument.uri) else {
			Log.error("could not find source for document uri")
			return
		}

		do {
			let formatted = try Formatter.format(source.text)
			handler.respond(to: request.id, with: [TextEdit(range: source.range, newText: formatted)])
		} catch {
			Log.error("Error formatting: \(error)")
		}
	}
}
