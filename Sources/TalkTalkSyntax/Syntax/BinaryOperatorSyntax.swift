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
}
