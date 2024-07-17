//
//  UnaryOperator.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct UnaryOperator: Syntax {
	public enum Kind {
		case minus, bang
	}

	public let start: Token
	public let end: Token
	public let kind: Kind

	public var description: String {
		switch kind {
		case .minus:
			"-"
		case .bang:
			"!"
		}
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
