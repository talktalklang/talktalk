//
//  SourceDocument.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct SourceDocument {
	let uri: String
	let range: Range
	var version: Int?
	var text: String

	init(textDocument: TextDocument) {
		self.init(version: textDocument.version, uri: textDocument.uri, text: textDocument.text ?? "")
	}

	init(version: Int?, uri: String, text: String) {
		let lines = text.components(separatedBy: .newlines)
		let lastLineCharacter = lines.isEmpty ? 0 : lines[lines.count-1].count
		self.range = Range(start: .init(line: 0, character: 0), end: .init(line: lines.count, character: lastLineCharacter))
		self.text = text
		self.uri = uri
	}
}
