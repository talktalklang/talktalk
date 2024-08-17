//
//  SourceDocument.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import TalkTalkSyntax

actor SourceDocument {
	let uri: String
	let range: Range
	var version: Int?
	var text: String
	var completer: Completer

	init(textDocument: TextDocument) async {
		await self.init(version: textDocument.version, uri: textDocument.uri, text: textDocument.text ?? "")
	}

	func update(text: String) async {
		await completer.update(text: text)
		self.text = text
	}

	init(version _: Int?, uri: String, text: String) async {
		let lines = text.components(separatedBy: .newlines)
		let lastLineCharacter = lines.isEmpty ? 0 : lines[lines.count - 1].count
		self.range = Range(start: .init(line: 0, character: 0), end: .init(line: lines.count, character: lastLineCharacter))
		self.text = text
		self.uri = uri
		self.completer = await Completer(source: SourceFile(path: uri, text: text))
	}
}
