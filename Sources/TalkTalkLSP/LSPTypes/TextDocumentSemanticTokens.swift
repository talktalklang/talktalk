//
//  TextDocumentSemanticTokens.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct RawSemanticToken: Encodable, Equatable {
	let lexeme: String
	let line: Int
	let startChar: Int
	let length: Int
	let tokenType: SemanticTokenTypes
	let modifiers: [SemanticTokenModifiers]
}

struct RelativeSemanticToken: Equatable {
	let lineDelta: Int
	let startDelta: Int
	let length: Int
	let tokenType: SemanticTokenTypes
	let modifiers: [SemanticTokenModifiers]
	let lexeme: String

	static func generate(from tokens: [RawSemanticToken]) -> [RelativeSemanticToken] {
		var lastLine = 0
		var lastStart = 0
		var result: [RelativeSemanticToken] = []

		for token in tokens.sorted(by: { ($0.line, $0.startChar) < ($1.line, $1.startChar) }) {
			if token.line == 0, token.startChar == 0, token.length == 0 {
				// Skip synthetic tokens
				continue
			}

			let lineDelta = token.line - lastLine
			let startDelta = (lineDelta == 0 ? token.startChar - lastStart : token.startChar)

			lastStart = token.startChar
			lastLine = token.line

			result.append(
				RelativeSemanticToken(
					lineDelta: lineDelta,
					startDelta: startDelta,
					length: token.length,
					tokenType: token.tokenType,
					modifiers: [],
					lexeme: token.lexeme
				)
			)
		}

		return result
	}

	var serialized: [Int] {
		[
			lineDelta,
			startDelta,
			length,
			SemanticTokensLegend.lookup(tokenType),
			0
		]
	}
}

struct TextDocumentSemanticTokens: Codable {
	let data: [Int]
}
