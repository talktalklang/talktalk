//
//  ParserRules.swift
//  
//
//  Created by Pat Nakajima on 7/1/24.
//
typealias ParseFunction = (inout Compiler) -> Void

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
		case .leftParen: 		.init({ $0.grouping() }, nil, .none)
		case .rightParen: 	.none
		case .leftBrace: 		.none
		case .rightBrace: 	.none
		case .comma: 				.none
		case .dot: 					.none
		case .minus: 				.init({ $0.unary() }, { $0.binary() }, .term)
		case .plus:         .init(nil, { $0.binary() }, .term)
		case .semicolon:		.none
		case .slash:				.init(nil, { $0.binary() }, .factor)
		case .star:					.init(nil, { $0.binary() }, .factor)
		case .bang:					.none
		case .bangEqual:		.none
		case .equal:				.none
		case .equalEqual:		.none
		case .greater:			.none
		case .greaterEqual:	.none
		case .less:					.none
		case .lessEqual:		.none
		case .and:					.none
		case .andAnd:				.none
		case .pipe:					.none
		case .pipePipe:			.none
		case .identifier:		.none
		case .string:				.none
		case .number:				.init({ $0.number() }, nil, .none)
		case .class:				.none
		case .else:					.none
		case .false:				.none
		case .func:					.none
		case .initializer:	.none
		case .for:					.none
		case .if:						.none
		case .nil:					.none
		case .or:						.none
		case .print:				.none
		case .return:				.none
		case .super:				.none
		case .self:					.none
		case .true:					.none
		case .var:					.none
		case .while:				.none
		case .eof:					.none
		case .error(_):			.none
		}
	}
}
