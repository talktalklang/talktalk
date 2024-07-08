//
//  ParserRules.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//
typealias ParseFunction = (Compiler, Bool) -> Void

struct ParserRule {
	var prefix: ParseFunction?
	var infix: ParseFunction?
	var precedence: Parser.Precedence

	static var none: ParserRule { .init(nil, nil, .none) }

	init(_ prefix: ParseFunction? = nil, _ infix: ParseFunction? = nil, _ precedence: Parser.Precedence) {
		self.prefix = prefix
		self.infix = infix
		self.precedence = precedence
	}
}

extension Token.Kind {
	var rule: ParserRule {
		return switch self {
		case .leftParen: .init({ $0.grouping($1) }, { $0.call($1) }, .call)
		case .rightParen: .none
		case .leftBrace: .none
		case .rightBrace: .none
		case .comma: .none
		case .dot: .init(nil, { $0.dot($1) }, .call)
		case .minus: .init({ $0.unary($1) }, { $0.binary($1) }, .term)
		case .plus: .init(nil, { $0.binary($1) }, .term)
		case .semicolon: .none
		case .slash: .init(nil, { $0.binary($1) }, .factor)
		case .star: .init(nil, { $0.binary($1) }, .factor)
		case .bang: .init({ $0.unary($1) }, nil, .factor)
		case .bangEqual: .init(nil, { $0.binary($1) }, .equality)
		case .equal: .none
		case .equalEqual: .init(nil, { $0.binary($1) }, .equality)
		case .greater: .init(nil, { $0.binary($1) }, .comparison)
		case .greaterEqual: .init(nil, { $0.binary($1) }, .comparison)
		case .less: .init(nil, { $0.binary($1) }, .comparison)
		case .lessEqual: .init(nil, { $0.binary($1) }, .comparison)
		case .and: .none
		case .andAnd: .init(nil, { $0.and($1) }, .and)
		case .pipe: .none
		case .print: .none
		case .pipePipe: .init(nil, { $0.or($1) }, .or)
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
		case .super: .none
		case .self: .init({ $0._self($1) }, nil, .none)
		case .true: .init({ $0.literal($1) }, nil, .none)
		case .var: .none
		case .while: .none
		case .eof: .none
		case .error: .none
		case .newline: .none
		}
	}
}
