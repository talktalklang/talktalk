//
//  BinaryOperator.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct BinaryOperatorSyntax: Syntax {
	public enum Kind {
		case plus,
		     minus,
		     star,
		     slash,
		     equal,
		     equalEqual,
		     bangEqual,
		     greater,
		     greaterEqual,
		     less,
		     lessEqual,
		     dot
	}

	public var kind: Kind

	public var position: Int
	public var length: Int

	public var description: String {
		switch kind {
		case .plus:
			"+"
		case .minus:
			"-"
		case .star:
			"*"
		case .slash:
			"/"
		case .equal:
			"="
		case .equalEqual:
			"=="
		case .bangEqual:
			"!="
		case .greater:
			">"
		case .greaterEqual:
			">="
		case .less:
			"<"
		case .lessEqual:
			"<="
		case .dot:
			"."
		}
	}

	public var debugDescription: String {
		"""
		BinaryOperatorSyntax(position: \(position), length: \(length))
			kind: \(kind)
		"""
	}
}
