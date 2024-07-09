//
//  Parser.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//
extension Parser {
	enum Precedence: Int, Comparable {
		static func < (lhs: Parser.Precedence, rhs: Parser.Precedence) -> Bool {
			lhs.rawValue < rhs.rawValue
		}

		static func + (lhs: Precedence, rhs: Int) -> Precedence {
			Precedence(rawValue: lhs.rawValue + rhs) ?? .any
		}

		case none,
		     assignment, // =
		     or, // ||
		     and, // &&
		     equality, // == !=
		     comparison, // < > <= >=
		     term, // + -
		     factor, // * /
		     unary, // ! -
		     call, // . ()
		     primary,

		     any

		var canAssign: Bool {
			self <= .assignment
		}
	}
}
