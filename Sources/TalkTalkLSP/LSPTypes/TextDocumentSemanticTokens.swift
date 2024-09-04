//
//  TextDocumentSemanticTokens.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

public struct RawSemanticToken: Encodable, Equatable {
	public let lexeme: String
	public let line: Int
	public let position: Int
	public let startChar: Int
	public let length: Int
	public let tokenType: SemanticTokenTypes
	public let modifiers: [SemanticTokenModifiers]

	public init(
		lexeme: String,
		line: Int,
		position: Int,
		startChar: Int,
		length: Int,
		tokenType: SemanticTokenTypes,
		modifiers: [SemanticTokenModifiers]
	) {
		self.lexeme = lexeme
		self.line = line
		self.position = position
		self.startChar = startChar
		self.length = length
		self.tokenType = tokenType
		self.modifiers = modifiers
	}
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
			SemanticTokensLegend.lookup(tokenType) ?? -1,
			0,
		]
	}
}

struct TextDocumentSemanticTokens: Codable {
	let data: [Int]
}
