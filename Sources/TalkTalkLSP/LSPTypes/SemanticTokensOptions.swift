//
//  SemanticTokensOptions.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

enum SemanticTokenTypes: String, Codable {
	case type
	case `class`
	case `enum`
	case interface
	case `struct`
	case typeParameter
	case parameter
	case variable
	case property
	case enumMember
	case event
	case function
	case method
	case macro
	case keyword
	case modifier
	case comment
	case string
	case number
	case regexp
	case `operator`
}

enum SemanticTokenModifiers: String, Codable {
	case declaration, definition, deprecated
}

struct SemanticTokensLegend: Codable {
	enum CodingKeys: CodingKey {
		case tokenTypes, tokenModifiers
	}

	static func lookup(_ type: SemanticTokenTypes) -> Int {
		[.type: 0,
		 .struct: 1,
		 .parameter: 2,
		 .variable: 3,
		 .property: 4,
		 .function: 5,
		 .method: 6,
		 .keyword: 7,
		 .string: 8,
		 .number: 9,
		 .operator: 10,
		 .comment: 11][type]!
	}

	let tokenTypes: [SemanticTokenTypes] = [
		.type,
		.struct,
		.parameter,
		.variable,
		.property,
		.function,
		.method,
		.keyword,
		.string,
		.number,
		.operator,
		.comment,
	]

	let tokenModifiers: [SemanticTokenModifiers] = [
		.declaration,
		.definition,
		.deprecated,
	]
}

struct SemanticTokensOptions: Codable {
	enum CodingKeys: CodingKey {
		case legend, range, full
	}

	let legend: SemanticTokensLegend = .init()
	let range = false
	let full = true
}
