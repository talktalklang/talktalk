//
//  HTML.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/20/24.
//

import ArgumentParser
import TalkTalkLSP
import TalkTalkSyntax
import TalkTalkCore

struct HTML: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Syntax highlight some TalkTalk as HTML"
	)

	@ArgumentParser.Argument(help: "The input to format.", completion: .file(extensions: [".talk"]))
	var input: String

	func run() async throws {
		let source = try get(input: input)
		let formatted = try HTMLHighlighter(input: source).highlight()
		print(formatted)
	}
}

struct HTMLHighlighter {
	let input: SourceFile
	let parsed: [any Syntax]

	init(input: SourceFile) throws {
		self.input = input
		self.parsed = try Parser.parse(input)
	}

	func highlight() -> String {
		let visitor = SemanticTokensVisitor()
		var tokens = try! parsed.flatMap { try $0.accept(visitor, .topLevel) }

		// Add in comment tokens since we lost those during parsing
		for match in input.text.matches(of: #/(\/\/[^\n]*)\n/#) {
			let start = match.range.lowerBound.utf16Offset(in: input.text)
			let end = match.range.upperBound.utf16Offset(in: input.text)

			tokens.append(
				.init(
					lexeme: String(match.output.1),
					line: -1,
					position: start,
					startChar: -1,
					length: end - start,
					tokenType: .comment,
					modifiers: []
				)
			)
		}

		var output = input.text
		var offset = 0

		for token in tokens.sorted(by: { $0.position < $1.position }) {
			let start = output.index(output.startIndex, offsetBy: token.position + offset)
			let end = output.index(start, offsetBy: token.length)
			let text = output[start..<end]
			let prefix = "<span class=\"\(token.tokenType.rawValue)\">"
			let suffix = "</span>"

			offset += prefix.count + suffix.count

			output.replaceSubrange(start..<end, with: prefix + text + suffix)
		}

		return output
	}
}
