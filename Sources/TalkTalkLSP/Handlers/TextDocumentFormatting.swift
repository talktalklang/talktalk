//
//  TextDocumentFormatting.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import Foundation
import TalkTalkSyntax
import TalkTalkCore

struct TextDocumentFormatting {
	var request: Request
//
//	func readFromDisk(uri: String) async -> SourceDocument? {
//		guard let url = URL(string: uri) else {
//			return nil
//		}
//
//		guard let string = try? String(contentsOf: url, encoding: .utf8) else {
//			return nil
//		}
//
//		return SourceDocument(version: nil, uri: uri, text: string)
//	}

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
