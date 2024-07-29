//
//  Parser+RulesTable.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//

struct ParserRule {
	typealias PrefixParseFunction = (inout Parser, Bool) -> any Expr
	typealias InfixParseFunction = (inout Parser, Bool, any Expr) -> any Expr

	var prefix: PrefixParseFunction?
	var infix: InfixParseFunction?
	var precedence: Parser.Precedence

	static var none: ParserRule { .init(nil, nil, .none) }

	init(
		_ prefix: PrefixParseFunction? = nil,
		_ infix: InfixParseFunction? = nil,
		_ precedence: Parser.Precedence
	) {
		self.prefix = prefix
		self.infix = infix
		self.precedence = precedence
	}
}

extension Token.Kind {
	var rule: ParserRule {
		return switch self {
		case .leftParen: .init({ $0.grouping($1) }, { $0.call($1, $2) }, .call)
		case .rightParen: .none
		case .leftBrace: .none
		case .rightBrace: .none
		case .identifier: .init({ $0.variable($1) }, nil, .none)

		// Binary ops
		case .plus: .init(nil, { $0.binary($1, $2) }, .term)
		case .equals: .none

		case .false: .init({ $0.literal($1) }, nil, .none)
		case .func: .init({ $0.literal($1) }, nil, .none)
		case .if: .init({ $0.ifExpr($1) }, nil, .none)
		case .else: .none
		case .true: .init({ $0.literal($1) }, nil, .none)
		case .eof: .none
		case .error: .none
		case .newline: .none
		case .symbol: .none
		case .int: .init({ $0.literal($1) }, nil, .none)
		case .float: .init({ $0.literal($1) }, nil, .none)
		case .in: .none
		case .call: .none
		case .comma: .none
		}
	}
}
