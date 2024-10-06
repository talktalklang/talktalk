//
//  TextDocumentFormatting.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import Foundation
import TalkTalkCore
import TalkTalkCore

struct TextDocumentFormatting {
	var request: Request

	func format(_ sources: [String: SourceDocument]) -> [TextEdit]? {
		guard let params = request.params as? TextDocumentFormattingRequest else {
			Log.error("Could not parse TextDocumentFormattingRequest params")
			return nil
		}

		guard let source = sources[params.textDocument.uri] else {
			Log.error("could not find source for document uri")
			return nil
		}

		do {
			Log.info("Formatting \(params.textDocument.uri)")
			let formatted = try Formatter(input: .init(path: params.textDocument.uri, text: params.textDocument.text ?? source.text)).format()
			let parts = formatted.components(separatedBy: .newlines)

			let fullRange = Range(
				start: Position(line: 0, character: 0),
				end: max(Position(line: parts.count, character: parts.last?.count ?? 0), source.range.end)
			)

			return [TextEdit(range: fullRange, newText: formatted)]
		} catch {
			Log.error("Error formatting: \(error)")
			return nil
		}
	}
}
