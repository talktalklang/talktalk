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
		     dot,
		     andAnd,
		     pipePipe
	}

	public var kind: Kind

	public let start: Token
	public let end: Token

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
		case .andAnd:
			"&&"
		case .pipePipe:
			"||"
		}
	}

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
