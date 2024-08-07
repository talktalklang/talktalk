//
//  SemanticTokensOptions.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

enum SemanticTokenTypes: String, Encodable {
	case type = "type"
	case `class` = "class"
	case `enum` = "enum"
	case interface = "interface"
	case `struct` = "struct"
	case typeParameter = "typeParameter"
	case parameter = "parameter"
	case variable = "variable"
	case property = "property"
	case enumMember = "enumMember"
	case event = "event"
	case function = "function"
	case method = "method"
	case macro = "macro"
	case keyword = "keyword"
	case modifier = "modifier"
	case comment = "comment"
	case string = "string"
	case number = "number"
	case regexp = "regexp"
	case `operator` = "operator"
}

enum SemanticTokenModifiers: String, Encodable {
	case declaration, definition, deprecated
}

struct SemanticTokensLegend: Encodable {
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
		 .operator: 10][type]!
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
		.operator
	]

	let tokenModifiers: [SemanticTokenModifiers] = [
		.declaration,
		.definition,
		.deprecated
	]
}

struct SemanticTokensOptions: Encodable {
	let legend: SemanticTokensLegend = .init()
	let range = false
	let full = true
}
