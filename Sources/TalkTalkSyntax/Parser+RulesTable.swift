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
		case .comma: .none
		case .dot: .init(nil, { $0.dot($1, $2) }, .call)
		case .minus: .init({ $0.unary($1) }, { $0.binary($1, $2) }, .term)
		case .plus: .init(nil, { $0.binary($1, $2) }, .term)
		case .semicolon: .none
		case .slash: .init(nil, { $0.binary($1, $2) }, .factor)
		case .star: .init(nil, { $0.binary($1, $2) }, .factor)
		case .bang: .init({ $0.unary($1) }, nil, .factor)
		case .bangEqual: .init(nil, { $0.binary($1, $2) }, .equality)
		case .equal: .none
		case .equalEqual: .init(nil, { $0.binary($1, $2) }, .equality)
		case .greater: .init(nil, { $0.binary($1, $2) }, .comparison)
		case .greaterEqual: .init(nil, { $0.binary($1, $2) }, .comparison)
		case .less: .init(nil, { $0.binary($1, $2) }, .comparison)
		case .lessEqual: .init(nil, { $0.binary($1, $2) }, .comparison)
		case .and: .none
		case .andAnd: .init(nil, { $0.and($1, $2) }, .and)
		case .pipe: .none
		case .print: .none
		case .pipePipe: .init(nil, { $0.or($1, $2) }, .or)
		case .identifier: .init({ $0.variable($1) }, nil, .none)
		case .string: .init({ $0.string($1) }, nil, .none)
		case .number: .init({ $0.number($1) }, nil, .none)
		case .class: .none
		case .else: .none
		case .false: .init({ $0.literal($1) }, nil, .none)
		case .func: .none
		case .`init`: .none
		case .for: .none
		case .if: .none
		case .nil: .init({ $0.literal($1) }, nil, .none)
		case .or: .none
		case .return: .none
		case .super: .init({ $0._super($1) }, nil, .none)
		case .self: .init({ $0._self($1) }, nil, .none)
		case .true: .init({ $0.literal($1) }, nil, .none)
		case .var: .none
		case .while: .none
		case .eof: .none
		case .error: .none
		case .newline: .none
		case .colon: .none
		case .leftBracket: .init({ $0.arrayLiteral($1) }, { $0.call($1, $2) }, .call)
		case .rightBracket: .none
		}
	}
}
